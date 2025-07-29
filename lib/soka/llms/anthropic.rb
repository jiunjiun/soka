# frozen_string_literal: true

module Soka
  module LLMs
    # Anthropic (Claude) LLM provider implementation
    class Anthropic < Base
      ENV_KEY = 'ANTHROPIC_API_KEY'

      private

      def default_model
        'claude-sonnet-4-0'
      end

      def base_url
        'https://api.anthropic.com'
      end

      def default_options
        {
          temperature: 0.7,
          top_p: 1.0,
          top_k: 1,
          max_tokens: 2048,
          anthropic_version: '2023-06-01'
        }
      end

      public

      def chat(messages, **params)
        request_params = build_request_params(messages, params)

        response = connection.post do |req|
          req.url '/v1/messages'
          req.headers['x-api-key'] = api_key
          req.headers['anthropic-version'] = options[:anthropic_version]
          req.body = request_params
        end

        parse_response(response)
      rescue Faraday::Error => e
        handle_error(e)
      end

      private

      def build_request_params(messages, params)
        formatted_messages, system_prompt = extract_system_prompt(messages)
        request = build_base_request(formatted_messages, params)
        request[:system] = system_prompt if system_prompt
        request
      end

      def build_base_request(formatted_messages, params)
        {
          model: model,
          messages: formatted_messages,
          temperature: params[:temperature] || options[:temperature],
          top_p: params[:top_p] || options[:top_p],
          top_k: params[:top_k] || options[:top_k],
          max_tokens: params[:max_tokens] || options[:max_tokens]
        }
      end

      def extract_system_prompt(messages)
        system_message = messages.find { |m| m[:role] == 'system' }
        other_messages = messages.reject { |m| m[:role] == 'system' }

        formatted_messages = other_messages.map do |message|
          {
            role: map_role(message[:role]),
            content: message[:content]
          }
        end

        [formatted_messages, system_message&.dig(:content)]
      end

      def map_role(role)
        case role.to_s
        when 'user'
          'user'
        when 'assistant'
          'assistant'
        else
          role.to_s
        end
      end

      def parse_response(response)
        body = response.body
        validate_response_status(response.status, body)
        build_result_from_response(body)
      end

      def validate_response_status(status, body)
        return if status == 200

        error_message = body.dig('error', 'message') || 'Unknown error'
        raise LLMError, "Anthropic API error: #{error_message}"
      end

      def build_result_from_response(body)
        content = body.dig('content', 0, 'text')
        raise LLMError, 'No content in response' unless content

        Result.new(
          model: body['model'],
          content: content,
          input_tokens: body.dig('usage', 'input_tokens'),
          output_tokens: body.dig('usage', 'output_tokens'),
          finish_reason: body['stop_reason'],
          raw_response: body
        )
      end
    end
  end
end
