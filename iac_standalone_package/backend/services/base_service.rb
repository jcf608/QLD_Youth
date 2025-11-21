# frozen_string_literal: true

require_relative 'document_events'

# Base class for pipeline service objects
# Provides common patterns: initialization, event emission, error handling
#
# Subclasses must implement:
#   - #execute - Main service logic
#
# Subclasses may override:
#   - #validate! - Input validation (called before execute)
#
module Pipelines
  class BaseService
    class ServiceError < StandardError; end
    class ValidationError < ServiceError; end

    attr_reader :document, :options

    # Initialize service with document and options
    #
    # @param document [Document] Document to process
    # @param options [Hash] Service-specific options
    def initialize(document, options = {})
      @document = document
      @options = options
      validate!
    end

    # Call the service
    # This is the public interface - use `Service.call(document, options)`
    #
    # @return [Hash] Result with :success, :data, and optional :error
    def self.call(document, options = {})
      new(document, options).call
    end

    # Execute the service with error handling
    #
    # @return [Hash] Result with :success, :data, and optional :error
    def call
      result = execute
      emit_success_event(result)

      { success: true, data: result }
    rescue StandardError => e
      handle_error(e)
      emit_failure_event(e)

      { success: false, error: e.message, exception: e }
    end

    protected

    # Execute service logic (must be implemented by subclasses)
    #
    # @return [Hash] Service-specific result data
    def execute
      raise NotImplementedError, "#{self.class.name} must implement #execute"
    end

    # Validate inputs (override in subclasses if needed)
    #
    # @raise [ValidationError] If validation fails
    def validate!
      raise ValidationError, 'Document is required' if document.nil?
    end

    # Emit event through DocumentEvents
    #
    # @param event_type [Symbol] Event type
    # @param data [Hash] Event data
    def emit_event(event_type, data = {})
      DocumentEvents.emit(
        event_type,
        data.merge(
          service: self.class.name,
          document_id: document&.id
        )
      )
    end

    # Emit success event (override to customize)
    def emit_success_event(result)
      # Default: no-op, subclasses can override
    end

    # Emit failure event (override to customize)
    def emit_failure_event(error)
      emit_event(:service_failed, {
                   error_class: error.class.name,
                   error_message: error.message
                 })
    end

    # Handle service errors
    def handle_error(error)
      log_error(error)
      # Can add error tracking integration here (Sentry, Rollbar, etc.)
    end

    # Log error with context
    def log_error(error)
      DocumentEvents.logger.error({
        error_class: error.class.name,
        error_message: error.message,
        backtrace: error.backtrace&.first(5),
        document_id: document&.id,
        service: self.class.name
      }.to_json)
    end

    # Get logger instance
    def logger
      DocumentEvents.logger
    end
  end
end
