# frozen_string_literal: true

module Soka
  module Agents
    # Module for managing hooks and result processing
    module HookManager
      private

      # Run registered hooks for the given type
      # @param hook_type [Symbol] The type of hook (:before_action, :after_action, :on_error)
      # @param args [Array] Arguments to pass to the hook methods
      # @return [Object, nil] The result from on_error hooks, or nil
      def run_hooks(hook_type, ...)
        return unless self.class._hooks && self.class._hooks[hook_type]

        self.class._hooks[hook_type].each do |method_name|
          if respond_to?(method_name, true)
            result = send(method_name, ...)
            return result if hook_type == :on_error && result
          end
        end

        nil
      end

      # Convert engine result to final Result object
      # @param engine_result [Struct] The raw engine result
      # @return [Result] The converted result
      def convert_engine_result(engine_result)
        Result.new(
          input: engine_result.input,
          thoughts: engine_result.thoughts,
          final_answer: engine_result.final_answer,
          status: engine_result.status,
          error: engine_result.error,
          execution_time: engine_result.execution_time
        )
      end

      # Update conversation and thoughts memories
      # @param input [String] The original input
      # @param result [Result] The result to record
      def update_memories(input, result)
        # Update conversation memory
        @memory.add(role: 'user', content: input)
        @memory.add(role: 'assistant', content: result.final_answer) if result.final_answer

        # Update thoughts memory
        @thoughts_memory.add(input, result)
      end

      # Build an error result object
      # @param input [String] The original input
      # @param error [StandardError] The error that occurred
      # @return [Result] An error result
      def build_error_result(input, error)
        Result.new(
          input: input,
          thoughts: [],
          final_answer: nil,
          status: :failed,
          error: error.message
        )
      end
    end
  end
end
