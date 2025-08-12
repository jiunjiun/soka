# frozen_string_literal: true

module Soka
  module LLMs
    # OpenAI (GPT) LLM provider implementation
    class OpenAI < Base
      ENV_KEY = 'OPENAI_API_KEY'

      def chat(messages, **params)
        request_params = build_request_params(messages, params)

        response = connection.post do |req|
          req.url '/v1/responses'
          req.headers['Authorization'] = "Bearer #{api_key}"
          req.body = request_params
        end

        parse_response(response)
      rescue Faraday::Error => e
        handle_error(e)
      end

      private

      def default_model
        'gpt-5-mini'
      end

      def base_url
        'https://api.openai.com'
      end

      def build_request_params(messages, params)
        request_params = {
          model: model,
          input: messages
        }

        # Add max_output_tokens if provided (Responses API uses max_output_tokens)
        request_params[:max_output_tokens] = params[:max_tokens] if params[:max_tokens]
        add_reasoning_effort(request_params)

        request_params
      end

      def add_reasoning_effort(request_params)
        return unless allowed_reasoning_prefix_models?

        request_params[:reasoning] = { effort: 'minimal', summary: 'auto' }
      end

      def allowed_reasoning_prefix_models?
        model.start_with?('gpt-5') && !model.start_with?('gpt-5-chat-latest')
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
        # Extract text from the Responses API format
        output_text = extract_output_text(body['output'])

        # Get the status to determine finish reason
        finish_reason = body['status'] == 'completed' ? 'stop' : body['status']

        Result.new(
          model: body['model'],
          content: output_text,
          input_tokens: body.dig('usage', 'input_tokens'),
          output_tokens: body.dig('usage', 'output_tokens'),
          finish_reason: finish_reason,
          raw_response: body
        )
      end

      def extract_output_text(output_items)
        message = output_items.find { |item| item['type'] == 'message' }
        content = message['content'].find { |content| content['type'] == 'output_text' }
        content['text']
      end
    end
  end
end
