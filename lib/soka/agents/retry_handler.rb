# frozen_string_literal: true

module Soka
  module Agents
    # Module for handling retry logic
    module RetryHandler
      private

      # Execute a block with retry logic
      # @yield The block to execute with retries
      # @return [Object] The result of the block
      def with_retry(&)
        config = extract_retry_config
        execute_with_retries(config, &)
      end

      # Extract retry configuration with defaults
      # @return [Hash] The retry configuration
      def extract_retry_config
        config = self.class._retry_config
        {
          max_retries: config[:max_retries] || 3,
          backoff_strategy: config[:backoff_strategy] || :exponential,
          retry_on: config[:retry_on] || []
        }
      end

      # Execute with retry logic
      # @param config [Hash] Retry configuration
      # @yield The block to execute
      # @return [Object] The result of the block
      def execute_with_retries(config, &block)
        retries = 0
        begin
          block.call
        rescue StandardError => e
          raise e unless should_retry?(e, config[:retry_on]) && retries < config[:max_retries]

          retries += 1
          sleep(calculate_backoff(retries, config[:backoff_strategy]))
          retry
        end
      end

      # Check if error should trigger retry
      # @param error [StandardError] The error to check
      # @param retry_on [Array<Class>] Error classes to retry on
      # @return [Boolean] True if should retry
      def should_retry?(error, retry_on)
        return true if retry_on.empty?

        retry_on.any? { |error_class| error.is_a?(error_class) }
      end

      # Calculate backoff time
      # @param retries [Integer] Number of retries
      # @param strategy [Symbol] Backoff strategy
      # @return [Integer] Sleep time in seconds
      def calculate_backoff(retries, strategy)
        case strategy
        when :exponential
          2**(retries - 1)
        when :linear
          retries
        else
          1 # constant or unknown strategy
        end
      end
    end
  end
end
