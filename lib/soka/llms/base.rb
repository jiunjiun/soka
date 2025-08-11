# frozen_string_literal: true

module Soka
  module LLMs
    # Result structure for LLM responses
    Result = Struct.new(:model, :content, :input_tokens, :output_tokens, :finish_reason, :raw_response,
                        keyword_init: true) do
      def successful?
        !content.nil? && !content.empty?
      end
    end

    # Base class for LLM providers
    class Base
      attr_reader :model, :api_key, :options

      def initialize(model: nil, api_key: nil, **options)
        @model = model || default_model
        @api_key = api_key || api_key_from_env
        @options = default_options.merge(options)
        validate_configuration!
      end

      def chat(messages, **params)
        raise NotImplementedError, "#{self.class} must implement #chat method"
      end

      def streaming_chat(messages, **params, &)
        raise NotImplementedError, "#{self.class} does not support streaming"
      end

      def supports_streaming?
        false
      end

      private

      def default_model
        raise NotImplementedError, "#{self.class} must implement #default_model method"
      end

      def default_options
        {}
      end

      def validate_configuration!
        raise LLMError, 'API key is required' if api_key.nil? || api_key.empty?
        raise LLMError, 'Model is required' if model.nil? || model.empty?
      end

      def api_key_from_env
        ENV.fetch(self.class::ENV_KEY, nil)
      end

      def connection
        @connection ||= Faraday.new(url: base_url) do |faraday|
          faraday.request :json
          faraday.response :json
          faraday.adapter Faraday.default_adapter
          faraday.options.timeout = 60
        end
      end

      def base_url
        raise NotImplementedError, "#{self.class} must implement #base_url method"
      end

      def handle_error(error)
        case error
        when Faraday::TimeoutError
          raise LLMError, 'Request timed out'
        when Faraday::ConnectionFailed
          raise LLMError, "Connection failed: #{error.message}"
        when Faraday::ClientError
          handle_client_error(error)
        else
          raise LLMError, "Unexpected error: #{error.message}"
        end
      end

      def handle_client_error(error)
        status = error.response[:status]
        body = error.response[:body]
        raise_error_for_status(status, body)
      end

      def raise_error_for_status(status, body)
        error_message = build_error_message(status, body)
        raise LLMError, error_message
      end

      def build_error_message(status, body)
        case status
        when 401 then 'Unauthorized: Invalid API key'
        when 429 then 'Rate limit exceeded'
        when 400..499 then extract_error_message(body) || "Client error: #{status}"
        when 500..599 then "Server error: #{status}"
        else "HTTP error: #{status}"
        end
      end

      def extract_error_message(body)
        return body if body.is_a?(String)

        # Try common error message paths
        body.dig('error', 'message') ||
          body.dig('error', 'text') ||
          body['message'] ||
          body.to_s
      end
    end
  end
end
