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

        # Parse action block from LLM response in JSON format
        # @param content [String] The action block content containing JSON
        # @return [Hash, nil] The parsed action with tool and params
        def parse_action_block(content)
          content = content.strip
          action_json = JSON.parse(content, symbolize_names: true)

          return nil unless action_json[:tool]

          { tool: action_json[:tool], params: action_json[:parameters] || {} }
        rescue JSON::ParserError
          nil
        end
      end
    end
  end
end
