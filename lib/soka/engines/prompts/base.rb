# frozen_string_literal: true

module Soka
  module Engines
    module Prompts
      # Base module for prompt generation
      module Base
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
            #{react_base_prompt}

            #{react_framework_structure}

            You have access to the following tools:
            #{tools_description}

            #{format_instructions}

            #{custom_instructions_section(instructions)}
          PROMPT
        end

        def react_base_prompt
          'You are an AI assistant that uses the ReAct (Reasoning and Acting) framework to solve problems step by step.'
        end

        def react_framework_structure
          <<~STRUCTURE
            🔧 REACT FRAMEWORK STRUCTURE:
            You MUST use XML-style tags to structure your response. Each tag has a specific purpose:
            - <Thought>: Your first-person reasoning (max 30 words)
            - <Action>: Tool invocation with JSON parameters
            - <Observation>: Tool results (provided by system)
            - <FinalAnswer>: Your complete solution (direct & concise)

            These tags are MANDATORY and define the ReAct workflow. The system parses these tags to understand your reasoning process.
          STRUCTURE
        end

        def custom_instructions_section(instructions)
          <<~SECTION
            📋 CUSTOM BEHAVIOR INSTRUCTIONS:
            ═══════════════════════════════════════════
            The following instructions apply to the CONTENT within your XML tags, NOT the ReAct structure itself:

            #{instructions}

            ⚠️ IMPORTANT: These custom instructions modify HOW you think and respond within the tags,
            but DO NOT change the requirement to use the XML tag structure for ReAct.
            ═══════════════════════════════════════════
          SECTION
        end

        def format_instructions
          thinking_instruction = build_thinking_instruction(think_in)
          iteration_limit = build_iteration_limit_warning

          <<~INSTRUCTIONS
            #{iteration_limit}

            🎯 MANDATORY XML TAG STRUCTURE:
            You MUST use XML-style tags to wrap your content. This is NOT optional.
            The system relies on these tags to parse and understand your reasoning.

            #{thinking_instruction}

            #{step_format_example}

            #{action_format_rules}

            #{final_answer_critical_format}
          INSTRUCTIONS
        end
      end
    end
  end
end
