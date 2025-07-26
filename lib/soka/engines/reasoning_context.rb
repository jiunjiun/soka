# frozen_string_literal: true

module Soka
  module Engines
    # Context object that encapsulates all data needed during reasoning process
    # This eliminates the need to pass multiple parameters and blocks through method chains
    class ReasoningContext
      # Event structure for emitting events
      Event = Struct.new(:type, :content)

      attr_accessor :messages, :thoughts, :task, :iteration, :parsed_response
      attr_reader :event_handler, :max_iterations

      # Initialize a new reasoning context
      # @param task [String] The task to be processed
      # @param event_handler [Proc, nil] Optional block to handle events
      # @param max_iterations [Integer] Maximum number of reasoning iterations
      def initialize(task:, event_handler: nil, max_iterations: 10)
        @task = task
        @event_handler = event_handler
        @max_iterations = max_iterations
        @messages = []
        @thoughts = []
        @iteration = 0
        @parsed_response = nil
      end

      # Emit an event to the event handler if present
      # @param type [Symbol] The type of event (e.g., :thought, :action, :observation)
      # @param content [String, Hash] The content of the event
      def emit_event(type, content)
        return unless @event_handler

        event = Event.new(type, content)
        @event_handler.call(event)
      end

      # Check if we've reached the maximum number of iterations
      # @return [Boolean] true if max iterations reached
      def max_iterations_reached?
        @iteration >= @max_iterations
      end

      # Increment the iteration counter
      # @return [Integer] The new iteration count
      def increment_iteration!
        @iteration += 1
      end

      # Get the current iteration number (1-based for display)
      # @return [Integer] The current iteration number for display
      def current_step
        @iteration + 1
      end

      # Add a thought to the thoughts collection
      # @param thought [String] The thought content
      # @param action [Hash, nil] Optional action associated with the thought
      # @param observation [String, nil] Optional observation from action
      def add_thought(thought, action: nil, observation: nil)
        thought_data = { step: current_step, thought: thought }
        thought_data[:action] = action if action
        thought_data[:observation] = observation if observation
        @thoughts << thought_data
      end

      # Update the last thought with action and observation
      # @param action [Hash] The action that was taken
      # @param observation [String] The observation from the action
      def update_last_thought(action:, observation:)
        return if @thoughts.empty?

        @thoughts.last[:action] = action
        @thoughts.last[:observation] = observation
      end

      # Add a message to the conversation
      # @param role [String] The role of the message sender
      # @param content [String] The message content
      def add_message(role:, content:)
        @messages << { role: role, content: content }
      end

      # Get the last assistant message content
      # @return [String, nil] The content of the last assistant message
      def last_assistant_content
        last_assistant = @messages.reverse.find { |msg| msg[:role] == 'assistant' }
        last_assistant&.fetch(:content, nil)
      end
    end
  end
end
