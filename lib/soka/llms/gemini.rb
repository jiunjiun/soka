# frozen_string_literal: true

module Soka
  module LLMs
    # Google Gemini LLM provider implementation
    class Gemini < Base
      ENV_KEY = 'GEMINI_API_KEY'

      private

      def default_model
        'gemini-2.5-flash-lite'
      end

      def base_url
        'https://generativelanguage.googleapis.com'
      end

      def default_options
        {
          temperature: 0.7,
          top_p: 1.0,
          top_k: 1
        }
      end

      public

      def chat(messages, **params)
        request_params = build_request_params(messages, params)

        response = connection.post do |req|
          req.url "/v1beta/models/#{model}:generateContent"
          req.params['key'] = api_key
          req.body = request_params
        end

        parse_response(response)
      rescue Faraday::Error => e
        handle_error(e)
      end

      private

      def build_request_params(messages, params)
        {
          contents: format_messages(messages),
          generationConfig: {
            temperature: params[:temperature] || options[:temperature],
            topP: params[:top_p] || options[:top_p],
            topK: params[:top_k] || options[:top_k],
            thinkingConfig: { thinkingBudget: 512 }
          }
        }
      end

      def format_messages(messages)
        messages.map do |message|
          {
            role: map_role(message[:role]),
            parts: [{ text: message[:content] }]
          }
        end
      end

      def map_role(role)
        case role.to_s
        when 'system', 'assistant'
          'model'
        when 'user'
          'user'
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
        raise LLMError, "Gemini API error: #{error_message}"
      end

      def build_result_from_response(body)
        candidate = body.dig('candidates', 0)
        content = candidate.dig('content', 'parts', 0, 'text')

        Result.new(
          model: model,
          content: content,
          input_tokens: body.dig('usageMetadata', 'promptTokenCount'),
          output_tokens: body.dig('usageMetadata', 'candidatesTokenCount'),
          finish_reason: candidate['finishReason'],
          raw_response: body
        )
      end
    end
  end
end
