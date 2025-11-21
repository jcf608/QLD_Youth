# frozen_string_literal: true

require_relative 'base_service'

module Pipelines
  # Cloud deployment service for document processing infrastructure
  # Deploys Azure Form Recognizer, Storage, AI Search, etc.
  class CloudDeploymentService < BaseService
    SUPPORTED_PROVIDERS = %w[azure aws gcp].freeze

    # Azure deployment configuration
    # Define what resources to deploy and their dependencies
    AZURE_RESOURCES = [
      { type: :resource_group, method: :create_azure_resource_group, required: true },
      { type: :storage, method: :create_azure_storage, required: true },
      { type: :storage_container, method: :create_azure_storage_container, required: true, depends_on: :storage },
      { type: :form_recognizer, method: :create_azure_form_recognizer, required: true },
      { type: :search, method: :create_azure_search, required: true }
    ].freeze

    # Override initialization - this service doesn't need a document
    def initialize(options = {})
      @document = nil
      @options = options
      # Skip base validation since we don't have a document
    end

    # Override class method to not require document parameter
    def self.call(options = {})
      new(options).call
    end

    # Override validate - this service doesn't need a document
    def validate!
      # No validation needed at init time
    end

    def execute
      puts "[CloudDeployment] Starting deployment for provider: #{options[:provider]}"
      validate_provider!
      validate_credentials!

      result = case options[:provider]
               when 'azure'
                 deploy_azure_infrastructure
               when 'aws'
                 raise ServiceError, 'AWS deployment not yet implemented'
               when 'gcp'
                 raise ServiceError, 'GCP deployment not yet implemented'
               else
                 raise ServiceError, "Unsupported provider: #{options[:provider]}"
               end

      puts "[CloudDeployment] Deployment successful: #{result[:resources].size} resources created"
      result
    rescue StandardError => e
      puts "[CloudDeployment] ERROR: #{e.class.name} - #{e.message}"
      puts e.backtrace&.first(5)
      raise
    end

    private

    def validate_provider!
      provider = options[:provider]
      return if SUPPORTED_PROVIDERS.include?(provider)

      raise ServiceError, "Invalid provider. Must be one of: #{SUPPORTED_PROVIDERS.join(', ')}"
    end

    def validate_credentials!
      case options[:provider]
      when 'azure'
        validate_azure_credentials!
      end
    end

    def validate_azure_credentials!
      required = %w[AZURE_SUBSCRIPTION_ID AZURE_TENANT_ID]
      missing = required.select { |key| ENV[key].nil? || ENV[key].empty? }

      return if missing.empty?

      raise ServiceError, "Missing Azure credentials: #{missing.join(', ')}. " \
                         'Configure in Settings or set environment variables.'
    end

    def deploy_azure_infrastructure
      emit_event(:deployment_started, { provider: 'azure' })

      resources = []
      created_resources = {}

      # Deploy each resource defined in AZURE_RESOURCES configuration
      AZURE_RESOURCES.each do |resource_config|
        next unless resource_config[:required]

        # Call the deployment method
        if resource_config[:depends_on]
          # Resource depends on another (e.g., container depends on storage account)
          dependency = created_resources[resource_config[:depends_on]]
          result = send(resource_config[:method], dependency[:name])
        else
          result = send(resource_config[:method])
        end

        resources << result
        created_resources[resource_config[:type]] = result
      end

      emit_event(:deployment_completed, { provider: 'azure', resources: resources })

      {
        success: true,
        provider: 'azure',
        resources: resources,
        message: 'Azure infrastructure deployed successfully'
      }
    rescue StandardError => e
      emit_event(:deployment_failed, { provider: 'azure', error: e.message })
      raise ServiceError, "Deployment failed: #{e.message}"
    end

    def create_azure_resource_group
      rg_name = options[:resource_group] || "uts-#{environment}-rg"
      location = options[:location] || 'eastasia' # Works for Azure for Students

      # Check if resource group already exists
      check_result = `az group show --name #{rg_name} --output json 2>&1`

      if $?.success?
        existing_rg = JSON.parse(check_result)
        existing_location = existing_rg['location']

        if existing_location != location
          puts "[CloudDeployment] Resource group exists in #{existing_location}, deleting to recreate in #{location}..."
          `az group delete --name #{rg_name} --yes --no-wait 2>&1`
          sleep 3 # Wait for deletion to start
        else
          puts "[CloudDeployment] Using existing resource group in #{location}"
          return {
            type: 'resource_group',
            name: rg_name,
            location: existing_location,
            id: existing_rg['id'],
            existing: true
          }
        end
      end

      cmd = "az group create --name #{rg_name} --location #{location} --output json"
      result = execute_az_command(cmd, 'Creating resource group')

      {
        type: 'resource_group',
        name: rg_name,
        location: location,
        id: result['id']
      }
    end

    def create_azure_storage
      storage_name = options[:storage_account] || generate_storage_name
      rg_name = options[:resource_group] || "uts-#{environment}-rg"
      location = options[:location] || 'eastasia'  # Works for Azure for Students

      cmd = 'az storage account create ' \
            "--name #{storage_name} " \
            "--resource-group #{rg_name} " \
            "--location #{location} " \
            '--sku Standard_LRS ' \
            '--kind StorageV2 ' \
            '--output json'

      result = execute_az_command(cmd, 'Creating storage account')

      {
        type: 'storage_account',
        name: storage_name,
        endpoint: result['primaryEndpoints']['blob']
      }
    end

    def create_azure_storage_container(storage_account_name)
      container_name = ENV['AZURE_STORAGE_CONTAINER'] || 'documents'

      # Get storage account key
      rg_name = options[:resource_group] || "uts-#{environment}-rg"

      keys_cmd = 'az storage account keys list ' \
                 "--account-name #{storage_account_name} " \
                 "--resource-group #{rg_name} " \
                 '--output json'

      keys = execute_az_command(keys_cmd, 'Getting storage account keys')
      account_key = keys.first['value']

      # Create container
      cmd = 'az storage container create ' \
            "--name #{container_name} " \
            "--account-name #{storage_account_name} " \
            "--account-key #{account_key} " \
            '--output json'

      execute_az_command(cmd, 'Creating storage container')

      {
        type: 'storage_container',
        name: container_name,
        storage_account: storage_account_name
      }
    end

    def create_azure_form_recognizer
      service_name = options[:form_recognizer_name] || generate_form_recognizer_name
      rg_name = options[:resource_group] || "uts-#{environment}-rg"
      location = options[:location] || 'eastasia'  # Works for Azure for Students

      cmd = 'az cognitiveservices account create ' \
            "--name #{service_name} " \
            "--resource-group #{rg_name} " \
            "--location #{location} " \
            '--kind FormRecognizer ' \
            '--sku S0 ' \
            '--yes ' \
            '--output json'

      result = execute_az_command(cmd, 'Creating Form Recognizer service')

      # Wait for resource to be fully provisioned before getting keys
      puts '[CloudDeployment] Waiting for Form Recognizer to be ready...'
      sleep 10

      # Get keys with retry
      keys_cmd = 'az cognitiveservices account keys list ' \
                 "--name #{service_name} " \
                 "--resource-group #{rg_name} " \
                 '--output json'

      keys = execute_az_command(keys_cmd, 'Getting Form Recognizer keys')

      {
        type: 'form_recognizer',
        name: service_name,
        endpoint: result['properties']['endpoint'],
        key: keys['key1']
      }
    end

    def create_azure_search
      search_name = options[:search_service] || generate_search_name
      rg_name = options[:resource_group] || "uts-#{environment}-rg"
      location = options[:location] || 'eastasia' # Works for Azure for Students

      cmd = 'az search service create ' \
            "--name #{search_name} " \
            "--resource-group #{rg_name} " \
            "--location #{location} " \
            '--sku basic ' \
            '--output json'

      result = execute_az_command(cmd, 'Creating AI Search service')

      {
        type: 'search_service',
        name: search_name,
        endpoint: "https://#{search_name}.search.windows.net"
      }
    end

    def execute_az_command(command, description)
      puts "[CloudDeployment] Executing: #{description}"
      output = `#{command} 2>&1`

      unless $?.success?
        puts "[CloudDeployment] Command failed. Output: #{output[0..500]}"
        raise ServiceError, "#{description} failed: #{output}"
      end

      # Filter out Python warnings and extract JSON
      # Azure CLI outputs warnings before JSON sometimes
      json_output = output.lines.drop_while { |line| !line.strip.start_with?('{', '[') }.join

      # Try to parse JSON
      begin
        JSON.parse(json_output)
      rescue JSON::ParserError => e
        puts "[CloudDeployment] JSON parse failed. Cleaned output: #{json_output[0..500]}"
        raise ServiceError, "#{description} - Invalid JSON response from Azure CLI: #{e.message}"
      end
    end

    def generate_storage_name
      # Max 24 chars, lowercase, numbers only
      # Format: utsdevstor + 8 random chars = 18 chars total
      env_code = environment == 'production' ? 'prd' : 'dev'
      "uts#{env_code}stor#{SecureRandom.hex(4)}" # e.g., utsdevstor1a2b3c4d (18 chars)
    end

    def generate_form_recognizer_name
      # Can use hyphens
      env_code = environment == 'production' ? 'prd' : 'dev'
      "uts-#{env_code}-formrec-#{SecureRandom.hex(2)}" # e.g., uts-dev-formrec-a1b2
    end

    def generate_search_name
      # Must be lowercase, can use hyphens
      env_code = environment == 'production' ? 'prd' : 'dev'
      "uts-#{env_code}-search-#{SecureRandom.hex(2)}" # e.g., uts-dev-search-a1b2
    end

    def environment
      ENV['RACK_ENV'] || 'development'
    end
  end
end
