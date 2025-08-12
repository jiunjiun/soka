# frozen_string_literal: true

module Soka
  module Engines
    module Prompts
      # Module for building instruction components
      module Instructions
        private

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

          <<~INSTRUCTION
            🌐 THINKING LANGUAGE:
            Use #{language} for your reasoning WITHIN the <Thought> XML tags.
            This affects the content inside tags, not the tag structure itself.
          INSTRUCTION
        end

        # Step format example
        # @return [String] The step format example
        def step_format_example
          <<~FORMAT
            📝 XML TAG FORMAT FOR EACH STEP:

            1️⃣ THINKING PHASE (Required):
            <Thought>
            MAXIMUM 30 WORDS - Be extremely concise!
            Use first-person perspective (I, me, my).
            NEVER mention: "LLM", "AI", "formatting for", "organizing for someone".
            NEVER say: "I will act as", "I will play the role of", "as an expert".
            BE DIRECT: "I'll check", "Let me see", "Looking at this".
            Keep it light and witty within the word limit.
            </Thought>

            2️⃣ ACTION PHASE (When needed):
            <Action>
            {"tool": "tool_name", "parameters": {"param1": "value1", "param2": "value2"}}
            </Action>

            ⚠️ CRITICAL: Each tag MUST have both opening <TagName> and closing </TagName>.
            The content between tags follows any custom instructions provided.
          FORMAT
        end

        # Critical format for final answer
        # @return [String] The critical format instructions
        def final_answer_critical_format
          <<~CRITICAL
            ⚠️ CRITICAL - FINAL ANSWER XML TAG FORMAT:
            When you have the complete answer, YOU MUST use XML-style tags:

            <FinalAnswer>
            State the result directly without explanation.
            No justification or reasoning needed - just the answer.
            Maximum 300 words. Be direct and concise.
            </FinalAnswer>

            🚨 PARSER REQUIREMENTS:
            - The system parser REQUIRES both opening <FinalAnswer> and closing </FinalAnswer> tags
            - Without proper XML tags, the system CANNOT detect task completion
            - The tags are case-sensitive and must match exactly
            - Final answer MUST NOT exceed 300 words
            - NO over-explanation - direct results only
          CRITICAL
        end
      end
    end
  end
end
