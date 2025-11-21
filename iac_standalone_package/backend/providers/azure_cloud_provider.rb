# frozen_string_literal: true

require_relative 'base_cloud_provider'

module Providers
  # Azure cloud infrastructure provider
  # Handles Azure-specific deployment, resource listing, and destruction
  #
  # This provider knows how to query and manage Azure resources:
  # - Resource Groups
  # - Storage Accounts
  # - Storage Containers (within Storage Accounts)
  # - Cognitive Services (Form Recognizer)
  # - Search Services (AI Search)
  # - Any other Azure resources in managed resource groups
  class AzureCloudProvider < BaseCloudProvider
    STORAGE_ACCOUNT_TYPE = 'Microsoft.Storage/storageAccounts'
    CONTAINER_TYPE = 'Microsoft.Storage/containers'
    FORM_RECOGNIZER_TYPE = 'Microsoft.CognitiveServices/accounts'
    SEARCH_SERVICE_TYPE = 'Microsoft.Search/searchServices'

    def initialize(config: {})
      super(provider: 'azure', config: config)
    end

    # Test Azure CLI connection
    # @return [Hash] Connection test result
    def test_connection
      result = `az account show --output json 2>&1`

      if $?.success?
        account = JSON.parse(result)
        {
          success: true,
          provider: 'azure',
          account_name: account['name'],
          subscription_id: (account['id']&.slice(0, 8)&.+ '...')
        }
      else
        {
          success: false,
          error: 'Azure CLI not authenticated. Run: az login'
        }
      end
    rescue StandardError => e
      {
        success: false,
        error: "Azure test failed: #{e.message}"
      }
    end

    # Deploy Azure infrastructure
    # This method would call CloudDeploymentService - not implemented here to avoid duplication
    def deploy(options = {})
      raise NotImplementedError, 'Use CloudDeploymentService for deployment'
    end

    # Query complete Azure inventory - all resources in all resource groups
    # Optionally filters by AZURE_RESOURCE_GROUP_PREFIX environment variable
    #
    # Returns comprehensive inventory including:
    # - All resources at the resource group level
    # - Nested resources like storage containers
    # - Resource metadata (name, type, location)
    #
    # @return [Hash] Complete inventory with structure:
    #   {
    #     success: true/false,
    #     resource_groups: [
    #       {
    #         name: 'resource-group-name',
    #         location: 'region',
    #         resource_count: N,
    #         resources: [
    #           { name: 'resource-name', type: 'Microsoft.*/type', location: 'region' },
    #           ...
    #         ]
    #       },
    #       ...
    #     ],
    #     error: 'error message' (only if success: false)
    #   }
    def get_resources
      # Get configured resource group prefix (default to all groups if not set)
      rg_prefix = ENV['AZURE_RESOURCE_GROUP_PREFIX']

      # Query Azure for all resource groups
      rg_result = `az group list --query "[].name" --output json 2>&1`

      unless $?.success?
        return { success: false, error: 'Failed to list resource groups' }
      end

      resource_groups = JSON.parse(rg_result)

      # Filter by prefix if configured, otherwise return all
      filtered_rgs = if rg_prefix && !rg_prefix.empty?
        resource_groups.select { |rg| rg.downcase.include?(rg_prefix.downcase) }
      else
        resource_groups
      end

      if filtered_rgs.empty?
        return { success: true, resource_groups: [] }
      end

      # Get complete details for each resource group (including nested resources)
      all_resource_groups = filtered_rgs.map do |rg|
        get_resource_group_details(rg)
      end.compact

      { success: true, resource_groups: all_resource_groups }
    rescue StandardError => e
      { success: false, error: "Failed to get Azure resources: #{e.message}" }
    end

    # Destroy Azure resource group
    # @param resource_group [String] Resource group name
    # @return [Hash] Destruction result
    def destroy_resource_group(resource_group)
      # Verify resource group exists
      check_result = `az group exists --name "#{resource_group}" 2>&1`

      unless $?.success?
        return { success: false, error: 'Failed to check resource group' }
      end

      exists = check_result.strip.downcase == 'true'

      unless exists
        return { success: false, error: 'Resource group not found' }
      end

      # Delete the resource group (this deletes all resources within it)
      delete_result = `az group delete --name "#{resource_group}" --yes --no-wait 2>&1`

      if $?.success?
        {
          success: true,
          message: "Resource group '#{resource_group}' deletion initiated. This may take several minutes to complete."
        }
      else
        { success: false, error: "Failed to delete resource group: #{delete_result}" }
      end
    rescue StandardError => e
      { success: false, error: "Failed to destroy Azure resources: #{e.message}" }
    end

    private

    # Query and build complete inventory for a single resource group
    # This includes:
    # 1. Top-level resources (storage accounts, cognitive services, search services, etc.)
    # 2. Nested resources (containers within storage accounts)
    #
    # @param rg [String] Resource group name
    # @return [Hash, nil] Complete resource group inventory or nil on error
    def get_resource_group_details(rg)
      # Query all top-level resources in this resource group
      resources_result = `az resource list --resource-group "#{rg}" --output json 2>&1`

      return nil unless $?.success?

      resources = JSON.parse(resources_result)

      # Get resource group metadata (location)
      rg_info_result = `az group show --name "#{rg}" --query "{location:location}" --output json 2>&1`
      rg_info = $?.success? ? JSON.parse(rg_info_result) : {}

      # Format top-level resources
      formatted_resources = resources.map do |r|
        {
          name: r['name'],
          type: r['type'],
          location: r['location']
        }
      end

      # Query and add nested resources (storage containers)
      add_storage_containers!(formatted_resources, resources)

      {
        name: rg,
        location: rg_info['location'] || 'unknown',
        resource_count: formatted_resources.length,
        resources: formatted_resources
      }
    end

    # Query and add storage containers to inventory
    # Iterates through all storage accounts and queries their containers
    #
    # @param formatted_resources [Array] Array to append container resources to (mutated)
    # @param resources [Array] Raw Azure resources from resource group
    def add_storage_containers!(formatted_resources, resources)
      # Find all storage accounts in this resource group
      storage_accounts = resources.select { |r| r['type'] == STORAGE_ACCOUNT_TYPE }

      # Query containers for each storage account
      storage_accounts.each do |storage_account|
        containers = get_storage_containers(storage_account['name'])

        # Add each container as a nested resource
        containers.each do |container|
          formatted_resources << {
            name: "#{container} (container)",
            type: CONTAINER_TYPE,
            location: storage_account['location']
          }
        end
      end
    end

    # Query containers within a storage account
    # Uses Azure CLI with login authentication to list all containers
    #
    # Note: This method silently handles errors and returns empty array on failure
    # to ensure the overall inventory query completes even if container listing
    # fails for a specific storage account.
    #
    # @param storage_account_name [String] Storage account name
    # @return [Array<String>] Container names (empty array on error)
    def get_storage_containers(storage_account_name)
      # Suppress stderr warnings to avoid polluting JSON output
      # Azure CLI sometimes outputs deprecation warnings that break JSON parsing
      containers_result = `az storage container list --account-name "#{storage_account_name}" --auth-mode login --query "[].name" --output json 2>/dev/null`

      return [] unless $?.success?

      # Parse JSON output, handling edge cases
      result_lines = containers_result.strip
      return [] if result_lines.empty?

      # Find start of JSON array (in case there are any stray characters)
      json_start = result_lines.index('[')
      return [] unless json_start

      json_content = result_lines[json_start..-1]
      JSON.parse(json_content)
    rescue StandardError => e
      # Silent failure - prevents one storage account from breaking entire inventory
      # Uncomment for debugging: puts "Warning: Failed to get containers for #{storage_account_name}: #{e.message}"
      []
    end
  end
end
