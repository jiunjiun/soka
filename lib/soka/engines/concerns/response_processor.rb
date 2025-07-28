# frozen_string_literal: true

module Soka
  module Engines
    module Concerns
      # Module for processing responses in ReAct engine
      module ResponseProcessor
        include Concerns::PromptTemplate

        private

        # Process thoughts from parsed response
        # @param parsed_thoughts [Array<String>] The thoughts to process
        # @param context [ReasoningContext] The reasoning context
        def process_thoughts(parsed_thoughts, context)
          parsed_thoughts.each do |thought|
            context.emit_event(:thought, thought)
            context.add_thought(thought)
          end
        end

        # Process an action from the response
        # @param action [Hash] The action to process
        # @param context [ReasoningContext] The reasoning context
        # @param content [String] The raw response content
        def process_action(action, context, content)
          context.emit_event(:action, action)

          begin
            observation = execute_tool(action[:tool], action[:params])
            context.emit_event(:observation, observation)
            add_observation_to_messages(context, content, observation)
            context.update_last_thought(action: action, observation: observation)
          rescue ToolError => e
            handle_tool_error(e, context, action, content)
          end
        end

        # Add observation to messages in the context
        # @param context [ReasoningContext] The reasoning context
        # @param content [String] The assistant's response content
        # @param observation [String] The observation to add
        def add_observation_to_messages(context, content, observation)
          observation_text = format_observation(observation)
          context.add_message(role: 'assistant', content: content)
          context.add_message(role: 'user', content: observation_text)
        end

        # Handle tool execution errors
        # @param error [ToolError] The error that occurred
        # @param context [ReasoningContext] The reasoning context
        # @param action [Hash] The action that failed
        # @param content [String] The raw response content
        # @raise [ToolError] Re-raises the error to trigger on_error hooks and terminate reasoning
        def handle_tool_error(error, context, action, content)
          error_message = "Tool error: #{error.message}"
          context.emit_event(:error, error_message)

          # Add error as observation so AI can see what happened
          add_observation_to_messages(context, content, error_message)
          context.update_last_thought(action: action, observation: error_message)

          # Re-raise the error to propagate to agent level
          # This will trigger on_error hook and terminate the reasoning process
          # If you want reasoning to continue after tool errors, comment out this line
          # raise error
        end

        # Execute a tool with the given name and input
        # @param tool_name [String] The name of the tool to execute
        # @param tool_input [Hash] The input parameters for the tool
        # @return [String] The result of the tool execution
        # @raise [ToolError] If the tool is not found or execution fails
        def execute_tool(tool_name, tool_input)
          tool = tools.find { |t| t.class.tool_name == tool_name }
          raise ToolError, "Tool '#{tool_name}' not found" unless tool

          tool.call(**symbolize_keys(tool_input))
        rescue StandardError => e
          # Re-raise as ToolError to be caught by process_action
          raise ToolError, "Error executing tool: #{e.message}"
        end

        def symbolize_keys(hash)
          return {} unless hash.is_a?(Hash)

          hash.transform_keys(&:to_sym)
        end

        # Handle case when no action is found in response
        # @param context [ReasoningContext] The reasoning context
        # @param content [String] The raw response content
        def handle_no_action(context, content)
          context.add_message(role: 'assistant', content: content)
          context.add_message(
            role: 'user',
            content: 'Please follow the exact format with <Thought>, <Action>, and <Final_Answer> tags.'
          )
        end
      end
    end
  end
end
