# frozen_string_literal: true

module Soka
  module Agents
    # Module for building LLM instances
    module LLMBuilder
      private

      # Build LLM instance with configuration
      # @param options [Hash] Configuration options
      # @return [LLM] The LLM instance
      def build_llm(options)
        provider = get_config_value(:provider, options)
        model = get_config_value(:model, options)
        api_key = get_config_value(:api_key, options)

        LLM.new(provider, model: model, api_key: api_key)
      end

      # Get configuration value with fallback chain
      # @param key [Symbol] The configuration key
      # @param options [Hash] Configuration options
      # @return [Object] The configuration value
      def get_config_value(key, options)
        # Check options first, then class settings, finally global config
        options[key] ||
          self.class.send("_#{key}") ||
          Soka.configuration.ai.send(key)
      end
    end
  end
end
