# frozen_string_literal: true

require_relative '../../../libs/pipelines/cloud_deployment_service'
require_relative '../../../libs/pipelines/database_backup_service'
require_relative '../../../libs/domain/audit_log'
require_relative '../../../libs/providers/provider_factory'

module Routes
  module CloudDeploymentRoutes
    def self.registered(app)
      app.namespace '/api/v1/cloud' do
        # Get deployment status
        get '/status' do
          require_authentication!

          status = {
            azure: CloudDeploymentRoutes.check_azure_status,
            aws: CloudDeploymentRoutes.check_aws_status,
            gcp: CloudDeploymentRoutes.check_gcp_status
          }

          success_response({ providers: status })
        end

        # Deploy infrastructure to cloud provider (async)
        post '/deploy' do
          require_authentication!
          # TODO: Add admin check when AuthorizationService is fixed

          provider = json_params[:provider] || params['provider']
          halt 400, error_response('Provider required', code: 'MISSING_PROVIDER', status: 400) unless provider

          deployment_options = {
            resource_group: json_params[:resource_group],
            location: json_params[:location],
            storage_account: json_params[:storage_account],
            form_recognizer_name: json_params[:form_recognizer_name],
            search_service: json_params[:search_service]
          }.compact

          # Generate deployment ID
          deployment_id = "deploy_#{Time.now.to_i}_#{SecureRandom.hex(4)}"

          # Queue background job
          begin
            require 'sidekiq'
            require_relative '../../../apps/worker/workers/cloud_deployment_worker'
            CloudDeploymentWorker.perform_async(deployment_id, provider, deployment_options)

            success_response({
                               deployment_id: deployment_id,
                               message: 'Deployment started',
                               status_url: "/api/v1/cloud/deploy/#{deployment_id}/status"
                             }, status: 202)
          rescue LoadError, NameError
            # Sidekiq not available - run synchronously (fallback for dev)
            result = Pipelines::CloudDeploymentService.call(deployment_options.merge(provider: provider))

            if result[:success]
              AuditLog.log(
                action: 'cloud.deployed',
                user: current_user,
                status: 'success',
                resource_type: 'CloudInfrastructure',
                changes: { provider: provider, resources: result[:resources] }
              )

              success_response({
                                 message: result[:message],
                                 provider: result[:provider],
                                 resources: result[:resources]
                               }, status: 201)
            else
              error_response(result[:error], code: 'DEPLOYMENT_FAILED', status: 500)
            end
          end
        rescue Pipelines::BaseService::ServiceError => e
          error_response(e.message, code: 'DEPLOYMENT_ERROR', status: 400)
        end

        # Get deployment status
        get '/deploy/:deployment_id/status' do
          require_authentication!

          deployment_id = params['deployment_id']

          require 'redis'
          redis = Redis.new
          progress_json = redis.get("deployment:#{deployment_id}")
          redis.quit

          if progress_json
            progress = JSON.parse(progress_json)
            success_response(progress)
          else
            error_response('Deployment not found', code: 'NOT_FOUND', status: 404)
          end
        rescue StandardError => e
          error_response("Failed to get deployment status: #{e.message}", code: 'STATUS_ERROR', status: 500)
        end

        # Test cloud credentials
        post '/test' do
          require_authentication!

          provider_name = json_params[:provider] || params['provider']
          halt 400, error_response('Provider required', code: 'MISSING_PROVIDER', status: 400) unless provider_name

          begin
            cloud_provider = Providers::ProviderFactory.create_cloud_provider(provider: provider_name)
            result = cloud_provider.test_connection

            success_response(result)
          rescue Providers::ProviderFactory::ProviderNotFoundError => e
            error_response(e.message, code: 'INVALID_PROVIDER', status: 400)
          end
        end

        # Get cloud resources
        get '/resources' do
          require_authentication!

          provider_name = params['provider'] || 'azure'

          begin
            cloud_provider = Providers::ProviderFactory.create_cloud_provider(provider: provider_name)
            result = cloud_provider.get_resources

            if result[:success]
              success_response(result)
            else
              error_response(result[:error], code: 'RESOURCES_ERROR', status: 500)
            end
          rescue Providers::ProviderFactory::ProviderNotFoundError => e
            error_response(e.message, code: 'INVALID_PROVIDER', status: 400)
          end
        end

        # Destroy cloud infrastructure
        post '/destroy' do
          require_authentication!
          # TODO: Add admin check when AuthorizationService is fixed

          provider_name = json_params[:provider] || params['provider']
          resource_group = json_params[:resource_group] || params['resource_group']

          halt 400, error_response('Provider required', code: 'MISSING_PROVIDER', status: 400) unless provider_name
          halt 400, error_response('Resource group required', code: 'MISSING_RESOURCE_GROUP', status: 400) unless resource_group

          begin
            # STEP 1: Create timestamped database backup before destruction
            puts "⚠️  Creating database backup before destroying #{resource_group}..."
            backup_result = Pipelines::DatabaseBackupService.call

            unless backup_result[:success]
              halt 500, error_response(
                "Database backup failed: #{backup_result[:error]}. Aborting destruction for safety.",
                code: 'BACKUP_FAILED',
                status: 500
              )
            end

            puts "✅ Database backed up to: #{backup_result[:backup_file]}"

            # STEP 2: Destroy cloud infrastructure
            cloud_provider = Providers::ProviderFactory.create_cloud_provider(provider: provider_name)
            result = cloud_provider.destroy_resource_group(resource_group)

            if result[:success]
              # STEP 3: Clean up database references to deleted cloud resources
              cleanup_result = CloudDeploymentRoutes.cleanup_cloud_references(provider_name, resource_group)

              AuditLog.log(
                action: 'cloud.destroyed',
                user: current_user,
                status: 'success',
                resource_type: 'CloudInfrastructure',
                changes: {
                  provider: provider_name,
                  resource_group: resource_group,
                  backup_file: backup_result[:backup_file],
                  backup_size: backup_result[:size_formatted],
                  database_cleanup: cleanup_result
                }
              )

              success_response({
                message: result[:message],
                backup_file: backup_result[:backup_file],
                backup_size: backup_result[:size_formatted],
                database_cleanup: cleanup_result
              })
            else
              error_response(result[:error], code: 'DESTROY_FAILED', status: 500)
            end
          rescue Providers::ProviderFactory::ProviderNotFoundError => e
            error_response(e.message, code: 'INVALID_PROVIDER', status: 400)
          rescue StandardError => e
            error_response("Failed to destroy resources: #{e.message}", code: 'DESTROY_ERROR', status: 500)
          end
        end
      end
    end

    class << self
      # Clean up database references to deleted cloud resources
      # Removes RAG infrastructure data (chunks, embeddings, indexes) tied to destroyed cloud resources
      # Keeps provenance data (documents, document_versions) for historical record
      def cleanup_cloud_references(provider, resource_group)
        require_relative '../../../libs/domain/document'
        require_relative '../../../libs/domain/document_version'
        require_relative '../../../libs/domain/document_chunk'
        require_relative '../../../libs/domain/document_embedding'
        require_relative '../../../libs/domain/document_index_entry'
        require_relative '../../../libs/domain/processing_job'

        counts = {
          chunks_deleted: 0,
          embeddings_deleted: 0,
          index_entries_deleted: 0,
          processing_jobs_deleted: 0
        }

        # Find all document versions that reference the destroyed cloud provider
        affected_versions = DocumentVersion.where(source_cloud: provider)

        affected_versions.find_each do |version|
          # Delete chunks (and their embeddings via cascade)
          chunk_count = version.document_chunks.count
          version.document_chunks.destroy_all
          counts[:chunks_deleted] += chunk_count
        end

        # Delete index entries for this provider
        index_count = DocumentIndexEntry.where(provider: provider).count
        DocumentIndexEntry.where(provider: provider).destroy_all
        counts[:index_entries_deleted] = index_count

        # Delete processing jobs related to this provider
        job_count = ProcessingJob.where(provider: provider).count
        ProcessingJob.where(provider: provider).destroy_all
        counts[:processing_jobs_deleted] = job_count

        # Reset document status to 'pending' since they need to be reprocessed
        Document.where(id: affected_versions.pluck(:document_id)).update_all(
          status: 'pending',
          current_version_id: nil
        )

        puts "🧹 Cleaned up #{counts[:chunks_deleted]} chunks, #{counts[:index_entries_deleted]} index entries, #{counts[:processing_jobs_deleted]} jobs"
        counts
      rescue StandardError => e
        puts "⚠️  Warning: Database cleanup failed: #{e.message}"
        { error: e.message }
      end

      # Helper methods for legacy /status endpoint
      def check_azure_status
        return { configured: false, available: false } unless ENV['AZURE_SUBSCRIPTION_ID']

        {
          configured: true,
          subscription_id: (ENV['AZURE_SUBSCRIPTION_ID']&.slice(0, 8)&.+ '...'),
          form_recognizer_configured: ENV['AZURE_FORM_RECOGNIZER_ENDPOINT'].present?,
          storage_configured: ENV['AZURE_STORAGE_ACCOUNT'].present?,
          search_configured: ENV['AZURE_SEARCH_ENDPOINT'].present?
        }
      end

      def check_aws_status
        {
          configured: false,
          available: false,
          message: 'AWS deployment not yet implemented'
        }
      end

      def check_gcp_status
        {
          configured: false,
          available: false,
          message: 'GCP deployment not yet implemented'
        }
      end
    end
  end
end
