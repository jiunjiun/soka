# frozen_string_literal: true

module Soka
  module Agents
    # Module for building tools
    module ToolBuilder
      private

      # Build tools from configuration
      # @return [Array<AgentTool>] Array of tool instances
      def build_tools
        tools = build_configured_tools
        tools.empty? ? build_default_tools : tools
      end

      # Build tools from class configuration
      # @return [Array<AgentTool>] Array of configured tools
      def build_configured_tools
        self.class._tools.map do |tool_config|
          create_tool_from_config(tool_config)
        end
      end

      # Create tool instance from configuration
      # @param tool_config [Hash] Tool configuration
      # @return [AgentTool] The tool instance
      def create_tool_from_config(tool_config)
        case tool_config[:type]
        when :class
          tool_config[:class].new
        when :function
          build_function_tool(tool_config)
        end
      end

      # Build default tools from global configuration
      # @return [Array<AgentTool>] Array of default tools
      def build_default_tools
        return [] unless Soka.configuration.tools.any?

        Soka.configuration.tools.map(&:new)
      end

      # Build a function-based tool
      # @param config [Hash] Tool configuration
      # @return [AgentTool] The function tool instance
      def build_function_tool(config)
        tool_name = config[:name]
        description = config[:description]

        # Create a dynamic tool class
        dynamic_tool = create_dynamic_tool_class(tool_name, description)
        dynamic_tool.new.tap { |tool| tool.instance_variable_set(:@agent, self) }
      end

      # Create a dynamic tool class
      # @param tool_name [Symbol, String] The tool name
      # @param description [String] The tool description
      # @return [Class] The dynamic tool class
      def create_dynamic_tool_class(tool_name, description)
        Class.new(AgentTool) do
          desc description

          define_method :call do |**params|
            # Call the method on the agent instance
            raise ToolError, "Method #{tool_name} not found on agent" unless @agent.respond_to?(tool_name)

            @agent.send(tool_name, **params)
          end

          define_singleton_method :tool_name do
            tool_name.to_s
          end
        end
      end
    end
  end
end
