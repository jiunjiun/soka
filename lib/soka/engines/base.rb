# frozen_string_literal: true

module Soka
  module Engines
    # Base class for reasoning engines
    class Base
      attr_reader :agent, :llm, :tools, :max_iterations, :custom_instructions

      def initialize(agent, llm, tools, max_iterations, custom_instructions = nil)
        @agent = agent
        @llm = llm
        @tools = tools
        @max_iterations = max_iterations
        @custom_instructions = custom_instructions
      end

      def reason(task)
        raise NotImplementedError, "#{self.class} must implement #reason method"
      end

      protected

      def find_tool(name)
        tools.find { |tool| tool.class.tool_name == name.to_s.downcase }
      end

      def execute_tool(tool_name, params = {})
        tool = find_tool(tool_name)
        raise ToolError, "Tool not found: #{tool_name}" unless tool

        tool.execute(**params)
      end

      def emit_event(type, content)
        return unless block_given?

        event = Struct.new(:type, :content).new(type, content)
        yield(event)
      end

      def build_messages(task)
        messages = [system_message]
        add_memory_messages(messages)
        messages << user_message(task)
        messages
      end

      def system_message
        { role: 'system', content: system_prompt }
      end

      def add_memory_messages(messages)
        return unless agent.respond_to?(:memory) && agent.memory

        messages.concat(agent.memory.to_messages)
      end

      def user_message(task)
        { role: 'user', content: task }
      end

      def system_prompt
        # This should be overridden by specific engines
        'You are a helpful AI assistant.'
      end
    end
  end
end
