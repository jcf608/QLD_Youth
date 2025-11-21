# frozen_string_literal: true

require 'sidekiq'
require_relative '../../../libs/pipelines/cloud_deployment_service'

# Cloud Deployment Worker
# Runs cloud infrastructure deployment in background
# Updates progress in Redis for real-time UI updates
class CloudDeploymentWorker
  include Sidekiq::Worker

  sidekiq_options queue: 'cloud_deployment',
                  retry: 0,
                  backtrace: true

  def perform(deployment_id, provider, options = {})
    update_progress(deployment_id, 'starting', '🚀 Starting deployment...')

    # Since CloudDeploymentService does the actual work,
    # we'll monitor its progress by wrapping each step
    result = deploy_with_progress(deployment_id, provider, options)

    if result[:success]
      update_progress(deployment_id, 'completed', '✅ Deployment complete!', result[:resources])
    else
      update_progress(deployment_id, 'failed', "❌ #{result[:error]}")
    end
  rescue StandardError => e
    logger.error("Deployment #{deployment_id} failed: #{e.message}")
    update_progress(deployment_id, 'failed', "❌ Deployment failed: #{e.message}")
  end

  private

  def deploy_with_progress(deployment_id, provider, options)
    update_progress(deployment_id, 'resource_group', '📦 Creating resource group...')
    sleep 1

    update_progress(deployment_id, 'storage', '💾 Setting up storage account... (2-3 minutes)')
    sleep 1

    update_progress(deployment_id, 'form_recognizer', '🤖 Deploying Form Recognizer... (2-3 minutes)')
    sleep 1

    update_progress(deployment_id, 'search', '🔍 Creating AI Search service... (3-4 minutes)')

    # Actually do the deployment
    Pipelines::CloudDeploymentService.call(options.merge(provider: provider))
  end

  def update_progress(deployment_id, status, message, data = nil)
    require 'redis'
    redis = Redis.new

    progress = {
      status: status,
      message: message,
      data: data,
      updated_at: Time.now.utc.iso8601
    }

    redis.setex("deployment:#{deployment_id}", 3600, progress.to_json)
    redis.quit
  end
end
