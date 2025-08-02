# frozen_string_literal: true

module Soka
  module Engines
    module Concerns
      # Module for handling prompt templates in ReAct engine
      module PromptTemplate
        private

        def system_prompt
          # Use custom instructions if provided, otherwise use default ReAct prompt
          if custom_instructions
            combine_with_react_format(custom_instructions)
          else
            default_react_prompt
          end
        end

        def default_react_prompt
          tools_description = format_tools_description(tools)

          <<~PROMPT
            You are an AI assistant that uses the ReAct (Reasoning and Acting) framework to solve problems step by step.

            You have access to the following tools:
            #{tools_description}

            #{format_instructions}
          PROMPT
        end

        def combine_with_react_format(instructions)
          tools_description = format_tools_description(tools)

          <<~PROMPT
            #{instructions}

            You have access to the following tools:
            #{tools_description}

            #{format_instructions}
          PROMPT
        end

        def format_instructions
          thinking_instruction = build_thinking_instruction(think_in)

          <<~INSTRUCTIONS
            You must follow this exact format for each step:

            #{thinking_instruction}

            <Thought>Your reasoning about what to do next</Thought>
            <Action>
            Tool: tool_name
            Parameters: {"param1": "value1", "param2": "value2"}
            </Action>

            #{action_format_rules}
          INSTRUCTIONS
        end

        # Build thinking instruction based on language
        # @param language [String, nil] The language to use for thinking
        # @return [String] The thinking instruction
        def build_thinking_instruction(language)
          return '' unless language

          "Use #{language} for your reasoning in <Thought> tags."
        end

        # Action format rules
        # @return [String] The action format rules
        def action_format_rules
          <<~RULES
            STOP HERE after each Action. Do NOT include <Observation> in your response.
            The system will execute the tool and provide the observation.

            After receiving the observation, you can continue with more Thought/Action cycles or provide a final answer:

            <Final_Answer>Your complete answer to the user's question</Final_Answer>

            Important rules:
            1. Always start with a <Thought> to analyze the problem
            2. Use tools when you need information or to perform actions
            3. Parameters MUST be valid JSON format (e.g., {"query": "weather"} not {query: "weather"})
            4. For tools without parameters, use empty JSON object: {}
            5. NEVER include <Observation> tags - wait for the system to provide them
            6. Provide a clear and complete <Final_Answer> when done
            7. If you cannot complete the task, explain why in the <Final_Answer>
          RULES
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
      end
    end
  end
end
