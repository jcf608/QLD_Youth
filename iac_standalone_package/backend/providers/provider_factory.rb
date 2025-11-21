# frozen_string_literal: true

require_relative 'base_storage_adapter'
require_relative 'base_decomposer'
require_relative 'base_embedder'
require_relative 'base_indexer'
require_relative 'base_cloud_provider'
require_relative 'azure_blob_adapter'
require_relative 'azure_cloud_provider'
require_relative 'local_decomposer'
require_relative 'openai_embedder'
require_relative 'azure_search_indexer'
require_relative 'local_indexer'

# Provider factory for creating adapter instances
# Handles provider selection based on configuration and capabilities
#
# Purpose: Centralized provider instantiation with capability matching
# Features: Environment-based configuration, capability registration lookup
#
# Design Principles:
# - §1.2: No hardcoding - provider selection from configuration/database
# - §1.3: DRY - Single place for adapter instantiation
# - §9: Fail-fast - Raise errors for missing providers
#
module Providers
  class ProviderFactory
    class ProviderNotFoundError < StandardError; end
    class InvalidConfigurationError < StandardError; end

    # Storage adapter registry
    STORAGE_ADAPTERS = {
      'azure' => AzureBlobAdapter,
      'azure_blob' => AzureBlobAdapter
      # 'aws' => AwsS3Adapter,  # TODO: Implement
      # 'gcp' => GcsAdapter      # TODO: Implement
    }.freeze

    # Decomposer adapter registry
    DECOMPOSER_ADAPTERS = {
      'local' => LocalDecomposer
      # 'azure_doc_intelligence' => AzureDocIntelligenceAdapter,  # TODO: Implement
      # 'aws_textract' => AwsTextractAdapter,                     # TODO: Implement
    }.freeze

    # Embedder adapter registry
    EMBEDDER_ADAPTERS = {
      'openai' => OpenAIEmbedder,
      'openai_embedding' => OpenAIEmbedder
      # 'azure_openai' => AzureOpenAIEmbedder,  # TODO: Implement
      # 'cohere' => CohereEmbedder              # TODO: Implement
    }.freeze

    # Indexer adapter registry
    INDEXER_ADAPTERS = {
      'local' => LocalIndexer,
      'azure_search' => AzureSearchIndexer,
      'azure_ai_search' => AzureSearchIndexer
      # 'opensearch' => OpenSearchIndexer,      # TODO: Implement
      # 'pinecone' => PineconeIndexer           # TODO: Implement
    }.freeze

    # Cloud provider registry
    CLOUD_PROVIDERS = {
      'azure' => AzureCloudProvider
      # 'aws' => AwsCloudProvider,    # TODO: Implement
      # 'gcp' => GcpCloudProvider     # TODO: Implement
    }.freeze

    class << self
      # Create a storage adapter
      #
      # @param provider [String, nil] Provider name (nil = use preferred)
      # @param config [Hash] Provider configuration
      # @return [BaseStorageAdapter] Storage adapter instance
      # @raise [ProviderNotFoundError] If provider not found
      def create_storage(provider: nil, config: {})
        provider ||= preferred_provider(:storage)
        adapter_class = STORAGE_ADAPTERS[provider.to_s.downcase]

        raise ProviderNotFoundError, "Storage provider not found: #{provider}" unless adapter_class

        adapter_class.new(config: config)
      end

      # Create a decomposer adapter
      #
      # @param provider [String, nil] Provider name (nil = use preferred)
      # @param config [Hash] Provider configuration
      # @return [BaseDecomposer] Decomposer adapter instance
      # @raise [ProviderNotFoundError] If provider not found
      def create_decomposer(provider: nil, config: {})
        provider ||= preferred_provider(:decomposer)
        adapter_class = DECOMPOSER_ADAPTERS[provider.to_s.downcase]

        raise ProviderNotFoundError, "Decomposer provider not found: #{provider}" unless adapter_class

        adapter_class.new(provider: provider, config: config)
      end

      # Create an embedder adapter
      #
      # @param provider [String, nil] Provider name (nil = use preferred)
      # @param model [String, nil] Model name (provider-specific default if nil)
      # @param config [Hash] Provider configuration
      # @return [BaseEmbedder] Embedder adapter instance
      # @raise [ProviderNotFoundError] If provider not found
      def create_embedder(provider: nil, model: nil, config: {})
        provider ||= preferred_provider(:embedder)
        adapter_class = EMBEDDER_ADAPTERS[provider.to_s.downcase]

        raise ProviderNotFoundError, "Embedder provider not found: #{provider}" unless adapter_class

        # Pass model if specified
        if model
          adapter_class.new(model: model, config: config)
        else
          adapter_class.new(config: config)
        end
      end

      # Create an indexer adapter
      #
      # @param provider [String, nil] Provider name (nil = use preferred)
      # @param index_name [String] Index name
      # @param config [Hash] Provider configuration
      # @return [BaseIndexer] Indexer adapter instance
      # @raise [ProviderNotFoundError] If provider not found
      def create_indexer(index_name:, provider: nil, config: {})
        provider ||= preferred_provider(:indexer)
        adapter_class = INDEXER_ADAPTERS[provider.to_s.downcase]

        raise ProviderNotFoundError, "Indexer provider not found: #{provider}" unless adapter_class

        adapter_class.new(index_name: index_name, config: config)
      end

      # Find best provider for a capability (e.g., MIME type support)
      #
      # @param capability_type [Symbol] Type of capability (:storage, :decomposer, :embedder, :indexer)
      # @param requirements [Hash] Capability requirements (e.g., mime_type, dimensions)
      # @return [String, nil] Provider name or nil if none match
      def find_provider(capability_type:, requirements: {})
        case capability_type
        when :storage
          find_storage_provider(requirements)
        when :decomposer
          find_decomposer_provider(requirements)
        when :embedder
          find_embedder_provider(requirements)
        when :indexer
          find_indexer_provider(requirements)
        else
          raise ArgumentError, "Unknown capability type: #{capability_type}"
        end
      end

      # Get list of available providers for a capability type
      #
      # @param capability_type [Symbol] Type of capability
      # @return [Array<String>] List of provider names
      def available_providers(capability_type)
        case capability_type
        when :storage
          STORAGE_ADAPTERS.keys
        when :decomposer
          DECOMPOSER_ADAPTERS.keys
        when :embedder
          EMBEDDER_ADAPTERS.keys
        when :indexer
          INDEXER_ADAPTERS.keys
        else
          []
        end
      end

      # Check if a provider is available
      #
      # @param provider [String] Provider name
      # @param capability_type [Symbol] Type of capability
      # @return [Boolean] True if available
      def provider_available?(provider:, capability_type:)
        available_providers(capability_type).include?(provider.to_s.downcase)
      end

      # Create a cloud infrastructure provider
      #
      # @param provider [String] Provider name ('azure', 'aws', 'gcp')
      # @param config [Hash] Provider configuration
      # @return [BaseCloudProvider] Cloud provider instance
      # @raise [ProviderNotFoundError] If provider not found
      def create_cloud_provider(provider:, config: {})
        adapter_class = CLOUD_PROVIDERS[provider.to_s.downcase]

        raise ProviderNotFoundError, "Cloud provider not found: #{provider}" unless adapter_class

        adapter_class.new(config: config)
      end

      # Convenience methods for pipeline services
      # These wrap the create_* methods with slightly different signatures

      # Get storage adapter (convenience wrapper)
      #
      # @param provider [String] Provider name
      # @param config [Hash] Provider configuration
      # @return [BaseStorageAdapter] Storage adapter instance
      def get_storage_adapter(provider:, config: {})
        create_storage(provider: provider, config: config)
      end

      # Get decomposer (convenience wrapper)
      #
      # @param provider [String] Provider name
      # @param mime_type [String, nil] MIME type for capability matching
      # @param config [Hash] Provider configuration
      # @return [BaseDecomposer] Decomposer adapter instance
      def get_decomposer(provider:, mime_type: nil, config: {})
        # mime_type can be used for provider selection in future
        create_decomposer(provider: provider, config: config)
      end

      # Get embedder (convenience wrapper)
      #
      # @param provider [String] Provider name
      # @param model [String, nil] Model name
      # @param config [Hash] Provider configuration
      # @return [BaseEmbedder] Embedder adapter instance
      def get_embedder(provider:, model: nil, config: {})
        create_embedder(provider: provider, model: model, config: config)
      end

      # Get indexer (convenience wrapper)
      #
      # @param provider [String] Provider name
      # @param config [Hash] Provider configuration (should include index_name)
      # @return [BaseIndexer] Indexer adapter instance
      def get_indexer(provider:, config: {})
        index_name = config[:index_name] || config['index_name'] || ENV['VECTOR_INDEX_NAME'] || 'documents'
        create_indexer(provider: provider, index_name: index_name, config: config)
      end

      private

      # Get preferred provider from environment or defaults
      #
      # @param capability_type [Symbol] Type of capability
      # @return [String] Provider name
      def preferred_provider(capability_type)
        case capability_type
        when :storage
          ENV['PREFERRED_STORAGE_PROVIDER'] || 'azure'
        when :decomposer
          ENV['PREFERRED_DECOMPOSER_PROVIDER'] || 'local'
        when :embedder
          ENV['PREFERRED_EMBEDDER_PROVIDER'] || 'openai'
        when :indexer
          ENV['PREFERRED_INDEXER_PROVIDER'] || 'local'
        else
          raise ArgumentError, "Unknown capability type: #{capability_type}"
        end
      end

      # Find storage provider (currently all support all files)
      #
      # @param requirements [Hash] Requirements
      # @return [String] Provider name
      def find_storage_provider(requirements)
        # All storage providers support all file types
        # Prefer configured provider
        preferred_provider(:storage)
      end

      # Find decomposer provider that supports MIME type
      #
      # @param requirements [Hash] Requirements with :mime_type
      # @return [String, nil] Provider name or nil
      def find_decomposer_provider(requirements)
        mime_type = requirements[:mime_type]
        return preferred_provider(:decomposer) unless mime_type

        # TODO: Query capability_registrations table for MIME type support
        # For now, return preferred provider
        preferred_provider(:decomposer)
      end

      # Find embedder provider that supports requirements
      #
      # @param requirements [Hash] Requirements with :dimensions, :model
      # @return [String] Provider name
      def find_embedder_provider(requirements)
        # All embedder providers can embed any text
        # Model selection handled by create_embedder
        preferred_provider(:embedder)
      end

      # Find indexer provider that supports requirements
      #
      # @param requirements [Hash] Requirements with :vector_search, :keyword_search
      # @return [String] Provider name
      def find_indexer_provider(requirements)
        # All indexer providers support vector + keyword search
        preferred_provider(:indexer)
      end
    end
  end
end
