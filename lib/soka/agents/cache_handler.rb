# frozen_string_literal: true

module Soka
  module Agents
    # Module for handling caching functionality
    module CacheHandler
      private

      # Check if a cached result exists for the input
      # @param input [String] The input to check
      # @return [Result, nil] The cached result if available
      def check_cache(input)
        return nil unless @cache

        @cache_store ||= {}
        @cache_store[input]
      end

      # Cache the result for the given input
      # @param input [String] The input key
      # @param result [Result] The result to cache
      def cache_result(input, result)
        return unless @cache

        @cache_store ||= {}
        @cache_store[input] = result
      end

      # Check if caching is enabled and result is available
      # @param input [String] The input to check
      # @return [Boolean] True if cache is enabled and result exists
      def cached_result_available?(input)
        @cache && check_cache(input)
      end
    end
  end
end
