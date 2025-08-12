# frozen_string_literal: true

module Soka
  module Engines
    module Prompts
      # Module for ReAct workflow rules
      module WorkflowRules
        private

        # Action format rules
        # @return [String] The action format rules
        def action_format_rules
          <<~RULES
            🔄 REACT WORKFLOW WITH XML TAGS:

            STOP HERE after each Action. Do NOT include <Observation> in your response.
            The system will execute the tool and provide the observation wrapped in <Observation> tags.

            After receiving the observation, you can continue with more Thought/Action cycles or provide a final answer.

            #{react_flow_example}

            #{xml_tag_requirements}
          RULES
        end

        # ReAct flow example
        # @return [String] The ReAct flow example
        def react_flow_example
          <<~EXAMPLE
            📝 EXAMPLE OF COMPLETE REACT FLOW WITH XML TAGS:

            Step 1: Your response
            <Thought>Math problem! I'll use the calculator tool for 2+2.</Thought>
            <Action>{"tool": "calculator", "parameters": {"expression": "2+2"}}</Action>

            Step 2: System provides
            <Observation>4</Observation>

            Step 3: Your response
            <Thought>Got it - the answer is 4!</Thought>
            <FinalAnswer>4</FinalAnswer>
          EXAMPLE
        end

        # XML tag requirements
        # @return [String] The XML tag requirements
        def xml_tag_requirements
          <<~REQUIREMENTS
            🚨 XML TAG REQUIREMENTS AND RULES:

            1. 🏷️ MANDATORY XML STRUCTURE:
               - Always wrap content in appropriate XML tags
               - Tags: <Thought>, <Action>, <FinalAnswer>
               - Each tag MUST have matching closing tag

            2. 💭 THINKING PHASE:
               - Always start with <Thought>...</Thought>
               - MAXIMUM 30 WORDS per thought
               - Use first-person perspective (I, me, my)
               - AVOID: "LLM", "AI", "formatting for", "organizing for"
               - AVOID: "act as", "play role of", "as an expert", "I will be"
               - BE DIRECT: Use natural language like "I'll check", "Let me see"
               - Be concise and witty
               - Custom instructions affect HOW you think, not WHETHER you use tags

            3. 🔧 ACTION FORMAT:
               - <Action> content MUST be valid JSON on a single line
               - Format: {"tool": "name", "parameters": {...}}
               - Empty parameters: {"tool": "name", "parameters": {}}

            4. 👁️ OBSERVATION:
               - NEVER create <Observation> tags yourself
               - System provides these automatically

            5. ✅ FINAL ANSWER:
               - MUST use <FinalAnswer>...</FinalAnswer> tags
               - Both opening AND closing tags REQUIRED
               - System cannot detect completion without these tags
               - No text after closing </FinalAnswer> tag
               - Maximum 300 words
               - Direct results only - NO explanations or justifications

            6. 🎯 EFFICIENCY:
               - Limited iterations available
               - Think harder upfront to minimize tool calls
               - Prioritize essential actions

            7. 📋 CUSTOM INSTRUCTIONS SCOPE:
               - Custom instructions modify content WITHIN tags
               - They DO NOT change the XML tag structure requirement
               - ReAct workflow with XML tags is ALWAYS required
          REQUIREMENTS
        end
      end
    end
  end
end
