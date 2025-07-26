# frozen_string_literal: true

module Soka
  module Engines
    module Concerns
      # Module for handling prompt templates in ReAct engine
      module PromptTemplate
        private

        def system_prompt
          tools_description = format_tools_description(tools)

          <<~PROMPT
            You are an AI assistant that uses the ReAct (Reasoning and Acting) framework to solve problems step by step.

            You have access to the following tools:
            #{tools_description}

            #{format_instructions}
          PROMPT
        end

        def format_instructions
          <<~INSTRUCTIONS
            You must follow this exact format for each step:

            <Thought>Your reasoning about what to do next</Thought>
            <Action>
            Tool: tool_name
            Parameters: {"param1": "value1", "param2": "value2"}
            </Action>

            STOP HERE after each Action. Do NOT include <Observation> in your response.
            The system will execute the tool and provide the observation.

            After receiving the observation, you can continue with more Thought/Action cycles or provide a final answer:

            <Final_Answer>Your complete answer to the user's question</Final_Answer>

            Important rules:
            1. Always start with a <Thought> to analyze the problem
            2. Use tools when you need information or to perform actions
            3. Parameters must be valid JSON
            4. NEVER include <Observation> tags - wait for the system to provide them
            5. Provide a clear and complete <Final_Answer> when done
            6. If you cannot complete the task, explain why in the <Final_Answer>
          INSTRUCTIONS
        end

        def format_tools_description(tools)
          return 'No tools available.' if tools.empty?

          tools.map do |tool|
            schema = tool.class.to_h
            params_desc = format_parameters(schema[:parameters])

            "- #{schema[:name]}: #{schema[:description]}\n  Parameters: #{params_desc}"
          end.join("\n")
        end

        def format_parameters(params_schema)
          return 'none' if params_schema[:properties].empty?

          properties = params_schema[:properties].map do |name, config|
            required = params_schema[:required].include?(name.to_s) ? '(required)' : '(optional)'
            type = config[:type]
            desc = config[:description]

            "#{name} #{required} [#{type}] - #{desc}"
          end

          properties.join(', ')
        end

        def parse_response(text)
          thoughts = extract_tagged_content(text, 'Thought')
          actions = extract_actions(text)
          final_answer = extract_tagged_content(text, 'Final_Answer').first

          {
            thoughts: thoughts,
            actions: actions,
            final_answer: final_answer
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

        def parse_json_params(params_json)
          JSON.parse(params_json, symbolize_names: true)
        rescue JSON::ParserError
          {}
        end

        def format_observation(observation)
          "<Observation>#{observation}</Observation>"
        end
      end
    end
  end
end
