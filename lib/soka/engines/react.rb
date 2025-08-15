# frozen_string_literal: true

module Soka
  module Engines
    # ReAct (Reasoning and Acting) engine implementation
    class React < Base
      include Prompts
      include Concerns::ResponseProcessor
      include Concerns::ResponseParser
      include Concerns::ResultBuilder

      ReasonResult = Struct.new(:input, :thoughts, :final_answer, :status, :error, :execution_time,
                                keyword_init: true) do
        def successful?
          status == :success
        end
      end

      # Main reasoning entry point
      # @param task [String] The task to process
      # @yield [event] Optional block to handle events during execution
      # @return [ReasonResult] The result of the reasoning process
      def reason(task, &block)
        start_time = Time.now
        context = ReasoningContext.new(task: task, event_handler: block, max_iterations: max_iterations,
                                       think_in: think_in)
        context.messages = build_messages(task)

        result = iterate_reasoning(context)
        result ||= max_iterations_result(context)

        # Add execution time to the result
        execution_time = Time.now - start_time
        result.execution_time = execution_time if result.respond_to?(:execution_time=)
        result
      end

      # Iterate through reasoning cycles
      # @param context [ReasoningContext] The reasoning context
      # @return [ReasonResult, nil] The result if found, nil otherwise
      def iterate_reasoning(context)
        max_iterations.times do |index|
          context.iteration = index # Set current iteration number
          result = process_iteration(context)
          return result if result
        end
        # When max iterations reached, ensure iteration count is correct
        context.iteration = max_iterations
        nil
      end

      # Build result when max iterations reached
      # @param context [ReasoningContext] The reasoning context
      # @return [ReasonResult] The error result
      def max_iterations_result(context)
        context.emit_event(:error, "Maximum iterations (#{context.max_iterations}) reached")
        build_result(
          input: context.task,
          thoughts: context.thoughts,
          final_answer: "I couldn't complete the task within the maximum number of iterations.",
          status: :max_iterations_reached
        )
      end

      private

      # Process a single iteration of reasoning
      # @param context [ReasoningContext] The reasoning context
      # @return [ReasonResult, nil] The result if final answer found, nil otherwise
      def process_iteration(context)
        response = llm.chat(context.messages)
        content = response.content
        context.parsed_response = parse_response(content)

        process_parsed_response(context, content)
      end

      # Process the parsed response
      # @param context [ReasoningContext] The reasoning context
      # @param content [String] The raw response content
      # @return [ReasonResult, nil] The result if final answer found, nil otherwise
      def process_parsed_response(context, content)
        parsed = context.parsed_response
        process_thoughts(parsed[:thoughts], context)

        return process_final_answer(parsed[:final_answer], context) if parsed[:final_answer]

        handle_actions_or_no_action(parsed, context, content)
        nil
      end

      # Handle either actions or no action in response
      # @param parsed [Hash] The parsed response
      # @param context [ReasoningContext] The reasoning context
      # @param content [String] The raw response content
      def handle_actions_or_no_action(parsed, context, content)
        if parsed[:actions].any?
          process_action(parsed[:actions].first, context, content)
        else
          handle_no_action(context, content)
        end
      end

      # Process the final answer
      # @param final_answer [String] The final answer from the LLM
      # @param context [ReasoningContext] The reasoning context
      # @return [ReasonResult] The success result
      def process_final_answer(final_answer, context)
        context.emit_event(:final_answer, final_answer)
        build_result(
          input: context.task,
          thoughts: context.thoughts,
          final_answer: final_answer,
          status: :success
        )
      end
    end
  end
end
