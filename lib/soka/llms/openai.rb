# frozen_string_literal: true

module Soka
  module LLMs
    # OpenAI (GPT) LLM provider implementation
    class OpenAI < Base
      ENV_KEY = 'OPENAI_API_KEY'

      private

      def default_model
        'gpt-4.1-mini'
      end

      def base_url
        'https://api.openai.com'
      end

      def default_options
        {
          temperature: 0.7,
          top_p: 1.0,
          frequency_penalty: 0,
          presence_penalty: 0
        }
      end

      public

      def chat(messages, **params)
        request_params = build_request_params(messages, params)

        response = connection.post do |req|
          req.url '/v1/chat/completions'
          req.headers['Authorization'] = "Bearer #{api_key}"
          req.body = request_params
        end

        parse_response(response)
      rescue Faraday::Error => e
        handle_error(e)
      end

      private

      def build_request_params(messages, params)
        {
          model: model,
          messages: messages,
          temperature: params[:temperature] || options[:temperature],
          top_p: params[:top_p] || options[:top_p],
          frequency_penalty: params[:frequency_penalty] || options[:frequency_penalty],
          presence_penalty: params[:presence_penalty] || options[:presence_penalty]
        }
      end

      def parse_response(response)
        body = response.body
        validate_response_status(response.status, body)
        build_result_from_response(body)
      end

      def validate_response_status(status, body)
        return if status == 200

        error_message = body.dig('error', 'message') || 'Unknown error'
        raise LLMError, "OpenAI API error: #{error_message}"
      end

      def build_result_from_response(body)
        choice = body.dig('choices', 0)
        message = choice['message']

        Result.new(
          model: body['model'],
          content: message['content'],
          input_tokens: body.dig('usage', 'prompt_tokens'),
          output_tokens: body.dig('usage', 'completion_tokens'),
          finish_reason: choice['finish_reason'],
          raw_response: body
        )
      end
    end
  end
end
