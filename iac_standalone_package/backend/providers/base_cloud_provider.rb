# frozen_string_literal: true

module Providers
  # Base class for cloud infrastructure providers
  # Handles deployment, resource listing, and destruction
  #
  # Each cloud provider implementation is responsible for:
  # 1. Knowing how to query its complete inventory of assets
  # 2. Understanding the structure and hierarchy of its resources
  # 3. Querying both top-level and nested resources
  # 4. Handling provider-specific authentication and CLI commands
  # 5. Returning standardized data structures for interoperability
  #
  # Implementations should query comprehensive inventory including:
  # - Resource groups/projects
  # - Compute resources
  # - Storage accounts and containers
  # - Database services
  # - AI/ML services
  # - Networking resources
  # - Any other provider-specific resources
  class BaseCloudProvider
    class CloudProviderError < StandardError; end
    class AuthenticationError < CloudProviderError; end
    class DeploymentError < CloudProviderError; end

    attr_reader :provider, :config

    def initialize(provider:, config: {})
      @provider = provider
      @config = config
    end

    # Test connection to cloud provider
    # @return [Hash] Connection test result with :success, :provider, :account_name, :subscription_id
    def test_connection
      raise NotImplementedError, "#{self.class.name} must implement test_connection"
    end

    # Deploy infrastructure
    # @param options [Hash] Deployment options (resource_group, location, etc.)
    # @return [Hash] Deployment result with :success, :resources, :message
    def deploy(options = {})
      raise NotImplementedError, "#{self.class.name} must implement deploy"
    end

    # Query complete inventory of deployed resources
    # Each provider must implement this to return ALL resources it manages,
    # including nested resources (e.g., containers within storage accounts)
    #
    # This is the primary inventory method - the provider must know:
    # - How to query all resource groups/projects
    # - How to query resources within each group
    # - How to query nested resources
    # - How to handle errors gracefully (don't fail entire query if one resource fails)
    #
    # @return [Hash] Complete inventory with standardized structure:
    #   {
    #     success: true/false,
    #     resource_groups: [
    #       {
    #         name: 'group-name',
    #         location: 'region',
    #         resource_count: N,
    #         resources: [
    #           { name: 'resource-name', type: 'type', location: 'region' },
    #           ...
    #         ]
    #       },
    #       ...
    #     ],
    #     error: 'error message' (only present if success: false)
    #   }
    def get_resources
      raise NotImplementedError, "#{self.class.name} must implement get_resources to query its inventory"
    end

    # Destroy resource group and all resources within it
    # @param resource_group [String] Resource group name
    # @return [Hash] Destruction result with :success, :message
    def destroy_resource_group(resource_group)
      raise NotImplementedError, "#{self.class.name} must implement destroy_resource_group"
    end

    protected

    # Execute shell command and handle errors
    # @param command [String] Command to execute
    # @param description [String] Description for logging
    # @return [Hash] Parsed JSON result
    def execute_command(command, description)
      output = `#{command} 2>&1`

      unless $?.success?
        raise DeploymentError, "#{description} failed: #{output}"
      end

      JSON.parse(output)
    rescue JSON::ParserError => e
      raise DeploymentError, "#{description} - Invalid JSON response: #{e.message}"
    end
  end
end
