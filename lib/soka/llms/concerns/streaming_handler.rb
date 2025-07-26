# frozen_string_literal: true

module Soka
  module LLMs
    module Concerns
      # Module for handling streaming responses from OpenAI
      module StreamingHandler
        private

        # Stream chat completion
        # @param messages [Array<Hash>] The messages to send
        # @param params [Hash] Additional parameters
        # @yield [String] Yields each chunk of the response
        # @return [String] The complete response
        def stream_chat(messages, **params, &)
          return regular_chat(messages, **params) unless block_given?

          complete_response = +''
          request_params = build_request_params(messages, **params, stream: true)

          response = connection.post('/v1/chat/completions') do |req|
            req.body = request_params.to_json
          end

          handle_streaming_response(response, complete_response, &)
        end

        # Handle streaming response
        # @param response [Faraday::Response] The HTTP response
        # @param complete_response [String] Buffer for complete response
        # @yield [String] Yields each chunk
        # @return [String] The complete response
        def handle_streaming_response(response, complete_response)
          response.body.each_line do |line|
            chunk = process_streaming_line(line)
            next unless chunk

            complete_response << chunk
            yield chunk
          end
          complete_response
        end

        # Process a single streaming line
        # @param line [String] The line to process
        # @return [String, nil] The parsed chunk or nil
        def process_streaming_line(line)
          return nil if line.strip.empty? || !line.start_with?('data: ')

          data = line[6..].strip
          return nil if data == '[DONE]'

          parse_streaming_chunk(data)
        end

        # Parse a streaming chunk
        # @param data [String] The chunk data
        # @return [String, nil] The parsed content
        def parse_streaming_chunk(data)
          parsed = JSON.parse(data)
          parsed.dig('choices', 0, 'delta', 'content')
        rescue JSON::ParserError
          nil
        end

        # Perform regular (non-streaming) chat
        # @param messages [Array<Hash>] The messages
        # @param params [Hash] Additional parameters
        # @return [String] The response content
        def regular_chat(messages, **params)
          request_params = build_request_params(messages, **params)
          response = connection.post('/v1/chat/completions', request_params.to_json)
          parse_response(response)
        end
      end
    end
  end
end
