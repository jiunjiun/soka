# frozen_string_literal: true

module Soka
  # LLM wrapper class that delegates to specific provider implementations
  class LLM
    attr_reader :provider

    # Initialize LLM with specified provider
    # @param provider_name [Symbol, nil] The provider to use (:gemini, :openai, :anthropic)
    # @param options [Hash] Provider-specific options (model, api_key, etc.)
    def initialize(provider_name = nil, **options)
      provider_name ||= Soka.configuration.ai.provider

      # Merge configuration options if no explicit options provided
      if options.empty? && provider_name == Soka.configuration.ai.provider
        config = Soka.configuration.ai
        options = {
          api_key: config.api_key,
          model: config.model
        }.compact
      end

      @provider = create_provider(provider_name, **options)
    end

    # Chat with the LLM
    # @param messages [Array<Hash>] Array of message hashes with role and content
    # @param params [Hash] Additional parameters for the chat
    # @return [LLMs::Result] The chat result
    def chat(messages, **params)
      @provider.chat(messages, **params)
    end

    # Stream chat responses
    # @param messages [Array<Hash>] Array of message hashes
    # @param params [Hash] Additional parameters
    # @yield [chunk] Yields each response chunk
    def streaming_chat(messages, **params, &)
      @provider.streaming_chat(messages, **params, &)
    end

    # Check if provider supports streaming
    # @return [Boolean] True if streaming is supported
    def supports_streaming?
      @provider.supports_streaming?
    end

    # Get the model being used
    # @return [String] The model name
    def model
      @provider.model
    end

    # Build LLM instance from configuration object
    # @param config [Object] Configuration with provider, model, and api_key
    # @return [LLM] New LLM instance
    def self.build(config)
      options = {
        model: config.model,
        api_key: config.api_key
      }.compact

      new(config.provider, **options)
    end

    private

    # Create the appropriate provider instance
    # @param provider_name [Symbol] Provider type
    # @param options [Hash] Provider options
    # @return [LLMs::Base] Provider instance
    def create_provider(provider_name, **)
      case provider_name.to_sym
      when :gemini
        LLMs::Gemini.new(**)
      when :openai
        LLMs::OpenAI.new(**)
      when :anthropic
        LLMs::Anthropic.new(**)
      else
        raise LLMError, "Unknown LLM provider: #{provider_name}"
      end
    end
  end
end
