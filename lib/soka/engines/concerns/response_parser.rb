# frozen_string_literal: true

module Soka
  module Engines
    module Concerns
      # Module for parsing LLM responses in ReAct format
      module ResponseParser
        private

        def parse_response(text)
          extract_response_parts(text)
        end

        def extract_response_parts(text)
          {
            thoughts: extract_tagged_content(text, 'Thought'),
            actions: extract_actions(text),
            final_answer: extract_tagged_content(text, 'Final_Answer').first
          }
        end

        def extract_tagged_content(text, tag)
          pattern = %r{<#{tag}>(.*?)</#{tag}>}m
          text.scan(pattern).map { |match| match[0].strip }
        end

        def extract_actions(text)
          action_blocks = text.scan(%r{<Action>(.*?)</Action>}m)
          action_blocks.filter_map { |block| parse_action_block(block[0]) }
        end

        def parse_action_block(content)
          content = content.strip
          tool_match = content.match(/Tool:\s*(.+)/)
          params_match = content.match(/Parameters:\s*(.+)/m)

          return unless tool_match && params_match

          tool_name = tool_match[1].strip
          params_json = params_match[1].strip
          params = parse_json_params(params_json)

          { tool: tool_name, params: params }
        end

        # Parse JSON parameters from action block
        # @param params_json [String] The JSON string to parse
        # @return [Hash] The parsed parameters as a hash with symbol keys
        def parse_json_params(params_json)
          # Clean up the JSON string - remove any trailing commas or whitespace
          cleaned_json = params_json.strip.gsub(/,\s*}/, '}').gsub(/,\s*\]/, ']')
          JSON.parse(cleaned_json, symbolize_names: true)
        rescue JSON::ParserError
          # Return empty hash to continue when JSON parsing fails
          {}
        end
      end
    end
  end
end
