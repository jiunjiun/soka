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
            combine_with_react_format(custom_instructions).strip
          else
            default_react_prompt.strip
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
          iteration_limit = build_iteration_limit_warning

          <<~INSTRUCTIONS
            #{iteration_limit}

            You must follow this exact format for each step:

            #{thinking_instruction}

            #{step_format_example}

            #{action_format_rules}

            #{final_answer_critical_format}
          INSTRUCTIONS
        end

        # Step format example
        # @return [String] The step format example
        def step_format_example
          <<~FORMAT
            FORMAT FOR EACH STEP:
            <Thought>Your reasoning about what to do next</Thought>
            <Action>
            {"tool": "tool_name", "parameters": {"param1": "value1", "param2": "value2"}}
            </Action>
          FORMAT
        end

        # Critical format for final answer
        # @return [String] The critical format instructions
        def final_answer_critical_format
          <<~CRITICAL
            ⚠️ CRITICAL - FINAL ANSWER FORMAT:
            When you have the complete answer, YOU MUST use this exact format:
            <Final_Answer>
            Your complete answer here
            </Final_Answer>

            The system WILL NOT recognize your answer without both opening <Final_Answer> and closing </Final_Answer> tags.
          CRITICAL
        end

        # Build iteration limit warning
        # @return [String] The iteration limit warning
        def build_iteration_limit_warning
          return '' unless respond_to?(:max_iterations) && max_iterations

          <<~WARNING
            ⏰ ITERATION LIMIT: You have a maximum of #{max_iterations} iterations to complete this task.
            - Each Thought/Action cycle counts as one iteration
            - Plan your approach efficiently to stay within this limit
            - If you cannot complete the task within #{max_iterations} iterations, provide your best answer with what you have
          WARNING
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

            After receiving the observation, you can continue with more Thought/Action cycles or provide a final answer.

            📝 EXAMPLE OF COMPLETE FLOW:
            <Thought>I need to calculate something</Thought>
            <Action>
            {"tool": "calculator", "parameters": {"expression": "2+2"}}
            </Action>
            [System will provide: <Observation>4</Observation>]
            <Thought>Now I have the result, I can provide the final answer</Thought>
            <Final_Answer>
            The result of 2+2 is 4.
            </Final_Answer>

            ⚠️ CRITICAL RULES FOR FINAL ANSWER:
            - When you have gathered all necessary information, you MUST end with <Final_Answer>
            - The <Final_Answer> tag MUST have a matching closing </Final_Answer> tag
            - Format: <Final_Answer>Your complete answer</Final_Answer>
            - Do NOT write any text after </Final_Answer>
            - Do NOT provide answers without these tags - they are REQUIRED

            Important rules:
            1. Always start with a <Thought> to analyze the problem
            2. Use tools when you need information or to perform actions
            3. The <Action> content MUST be a single line of valid JSON
            4. Action format: {"tool": "tool_name", "parameters": {...}}
            5. For tools without parameters, use: {"tool": "tool_name", "parameters": {}}
            6. NEVER include <Observation> tags - wait for the system to provide them
            7. FINAL ANSWER IS MANDATORY: Use <Final_Answer>...</Final_Answer> tags
            8. Both opening AND closing tags are REQUIRED: <Final_Answer> and </Final_Answer>
            9. If you cannot complete the task, explain why inside <Final_Answer>...</Final_Answer>
            10. The system CANNOT recognize completion without proper <Final_Answer> tags
            11. Be efficient - you have limited iterations to complete the task
            12. Prioritize essential actions and avoid unnecessary exploration
          RULES
        end
      end
    end
  end
end
