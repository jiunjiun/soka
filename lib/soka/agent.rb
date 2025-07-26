# frozen_string_literal: true

module Soka
  # Base class for AI agents that use ReAct pattern
  class Agent
    include Agents::RetryHandler
    include Agents::ToolBuilder
    include Agents::HookManager
    include Agents::DSLMethods
    include Agents::LLMBuilder
    include Agents::CacheHandler

    attr_reader :llm, :tools, :memory, :thoughts_memory, :engine

    # Initialize a new Agent instance
    # @param memory [Memory, nil] The memory instance to use (defaults to new Memory)
    # @param engine [Class] The engine class to use (defaults to Engine::React)
    # @param options [Hash] Configuration options
    # @option options [Integer] :max_iterations Maximum iterations for reasoning
    # @option options [Integer] :timeout Timeout in seconds for operations
    # @option options [Boolean] :cache Whether to enable caching
    # @option options [Integer] :cache_ttl Cache time-to-live in seconds
    # @option options [Symbol] :provider LLM provider override
    # @option options [String] :model LLM model override
    # @option options [String] :api_key LLM API key override
    def initialize(memory: nil, engine: Engines::React, **options)
      @memory = memory || Memory.new
      @thoughts_memory = ThoughtsMemory.new
      @engine = engine

      # Initialize components
      @llm = build_llm(options)
      @tools = build_tools

      # Apply configuration with clear defaults
      apply_configuration(options)
    end

    # Apply configuration options with defaults
    # @param options [Hash] Configuration options
    def apply_configuration(options)
      @max_iterations = options[:max_iterations] || self.class._max_iterations || 10
      @timeout = options[:timeout] || self.class._timeout || 30
      @cache = options[:cache] || false
      @cache_ttl = options[:cache_ttl]
    end

    # Run the agent with the given input
    # @param input [String] The input query or task
    # @yield [event] Optional block to handle events during execution
    # @return [Result] The result of the agent's reasoning
    def run(input, &)
      validate_input(input)
      return check_cache(input) if cached_result_available?(input)

      execute_reasoning(input, &)
    rescue ArgumentError
      raise # Re-raise ArgumentError without handling
    rescue StandardError => e
      handle_error(e, input)
    end

    private

    # Validate the input is not empty
    # @param input [String] The input to validate
    # @raise [ArgumentError] If input is empty
    def validate_input(input)
      raise ArgumentError, 'Input cannot be empty' if input.to_s.strip.empty?
    end

    # Execute the reasoning process with hooks
    # @param input [String] The input query
    # @yield [event] Optional block to handle events
    # @return [Result] The reasoning result
    def execute_reasoning(input, &)
      run_hooks(:before_action, input)

      engine_result = perform_reasoning(input, &)
      result = convert_engine_result(engine_result)

      finalize_result(input, result)
      result
    end

    # Perform the actual reasoning using the engine
    # @param input [String] The input query
    # @yield [event] Optional block to handle events
    # @return [EngineResult] The raw engine result
    def perform_reasoning(input, &)
      engine_instance = @engine.new(self, @llm, @tools, @max_iterations)
      with_retry { engine_instance.reason(input, &) }
    end

    # Finalize the result by updating memories and caching
    # @param input [String] The original input
    # @param result [Result] The result to finalize
    def finalize_result(input, result)
      update_memories(input, result)
      run_hooks(:after_action, result)
      cache_result(input, result) if @cache
    end

    # Handle errors during execution
    # @param error [StandardError] The error that occurred
    # @param input [String] The original input
    # @return [Result] An error result
    # @raise [StandardError] Re-raises if on_error hook returns :stop
    def handle_error(error, input)
      error_action = run_hooks(:on_error, error, input)
      raise error if error_action == :stop

      build_error_result(input, error)
    end

    # Tool building methods are in ToolBuilder module
    # Retry handling methods are in RetryHandler module
    # LLM building methods are in LLMBuilder module
    # Hook management methods are in HookManager module
  end
end
