# frozen_string_literal: true

module Soka
  module Agents
    # Module for DSL methods
    module DSLMethods
      def self.included(base)
        base.extend(ClassMethods)
      end

      # Class methods for DSL
      module ClassMethods
        attr_accessor :_provider, :_model, :_api_key, :_max_iterations, :_timeout, :_tools, :_retry_config, :_hooks

        def inherited(subclass)
          super
          subclass._tools = []
          subclass._hooks = { before_action: [], after_action: [], on_error: [] }
          subclass._retry_config = {}
        end

        # Define provider for the agent
        # @param provider [Symbol] The LLM provider (:gemini, :openai, :anthropic)
        def provider(provider)
          @_provider = provider
        end

        # Define model for the agent
        # @param model [String] The model name (e.g., 'gemini-1.5-pro')
        def model(model)
          @_model = model
        end

        # Define API key for the agent
        # @param key [String] The API key
        def api_key(key)
          @_api_key = key
        end

        # Define maximum iterations for the agent
        # @param num [Integer] The maximum number of iterations
        def max_iterations(num)
          @_max_iterations = num
        end

        # Define timeout for the agent
        # @param duration [Integer] The timeout duration in seconds
        def timeout(duration)
          @_timeout = duration
        end

        # Register a tool for the agent
        # @param tool_class_or_name [Class, Symbol, String] The tool class or method name
        # @param description_or_options [String, Hash, nil] Description (for function tools) or options
        # @param options [Hash] Additional options (if description provided)
        def tool(tool_class_or_name, description_or_options = nil, options = {})
          if tool_class_or_name.is_a?(Symbol) || tool_class_or_name.is_a?(String)
            # Function tool - expects description and options
            add_function_tool(tool_class_or_name, description_or_options, options)
          else
            # Class tool - second parameter is options
            opts = description_or_options.is_a?(Hash) ? description_or_options : options
            add_class_tool(tool_class_or_name, opts)
          end
        end

        # Register multiple tools at once
        # @param tool_classes [Array<Class>] The tool classes to register
        def tools(*tool_classes)
          tool_classes.each { |tool_class| tool(tool_class) }
        end

        # Configure retry behavior
        # @yield Configuration block
        def retry_config(&)
          config = Agents::RetryConfig.new
          config.instance_eval(&)
          @_retry_config = config.to_h
        end

        # Register before_action hook
        # @param method_name [Symbol] The method to call before action
        def before_action(method_name)
          @_hooks[:before_action] << method_name
        end

        # Register after_action hook
        # @param method_name [Symbol] The method to call after action
        def after_action(method_name)
          @_hooks[:after_action] << method_name
        end

        # Register on_error hook
        # @param method_name [Symbol] The method to call on error
        def on_error(method_name)
          @_hooks[:on_error] << method_name
        end

        private

        def add_function_tool(name, description, options)
          @_tools << {
            type: :function,
            name: name,
            description: description,
            options: options
          }
        end

        def add_class_tool(tool_class, options)
          condition = options[:if]
          return unless condition.nil? || (condition.respond_to?(:call) ? condition.call : condition)

          @_tools << { type: :class, class: tool_class, options: options }
        end
      end
    end

    # Configuration for retry behavior
    class RetryConfig
      attr_accessor :max_retries, :backoff_strategy, :retry_on

      def initialize
        @max_retries = 3
        @backoff_strategy = :exponential
        @retry_on = []
      end

      # Convert to hash
      # @return [Hash] The configuration as a hash
      def to_h
        {
          max_retries: max_retries,
          backoff_strategy: backoff_strategy,
          retry_on: retry_on
        }
      end
    end
  end
end
