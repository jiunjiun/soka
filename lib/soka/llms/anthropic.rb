# frozen_string_literal: true

module Soka
  module LLMs
    # Anthropic (Claude) LLM provider implementation
    class Anthropic < Base
      include Concerns::ResponseParser

      ENV_KEY = 'ANTHROPIC_API_KEY'

      private

      def default_model
        'claude-4-sonnet'
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

      def supports_streaming?
        true
      end

      def streaming_chat(messages, **params, &)
        request_params = build_streaming_params(messages, params)
        execute_streaming_request(request_params, &)
      rescue Faraday::Error => e
        handle_error(e)
      end

      def build_streaming_params(messages, params)
        request_params = build_request_params(messages, params)
        request_params[:stream] = true
        request_params
      end

      def execute_streaming_request(request_params, &)
        connection.post('/v1/messages') do |req|
          req.headers['x-api-key'] = api_key
          req.headers['anthropic-version'] = options[:anthropic_version]
          req.body = request_params
          req.options.on_data = proc do |chunk, _overall_received_bytes|
            process_stream_chunk(chunk, &)
          end
        end
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

      # Response parsing methods are in ResponseParser module
    end
  end
end
