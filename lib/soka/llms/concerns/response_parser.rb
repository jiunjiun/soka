# frozen_string_literal: true

module Soka
  module LLMs
    module Concerns
      # Module for parsing Anthropic API responses
      module ResponseParser
        private

        # Parse API response
        # @param response [Faraday::Response] The HTTP response
        # @return [String] The parsed content
        # @raise [LLMError] If response indicates an error
        def parse_response(response)
          handle_error(response) unless response.success?

          data = JSON.parse(response.body)
          extract_content(data)
        end

        # Extract content from response data
        # @param data [Hash] The parsed response data
        # @return [String] The extracted content
        # @raise [LLMError] If content is missing
        def extract_content(data)
          content = data.dig('content', 0, 'text')
          raise LLMError, 'No content in response' unless content

          content
        end

        # Handle API errors
        # @param response [Faraday::Response] The HTTP response
        # @raise [LLMError] Always raises with error details
        def handle_error(response)
          error_data = begin
            JSON.parse(response.body)
          rescue StandardError
            {}
          end
          error_message = error_data.dig('error', 'message') || "HTTP #{response.status}"
          raise LLMError, "Anthropic API error: #{error_message}"
        end
      end
    end
  end
end
