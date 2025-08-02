# frozen_string_literal: true

module Soka
  # Base class for AI agents that use ReAct pattern
  class Agent
    include Agents::RetryHandler
    include Agents::ToolBuilder
    include Agents::HookManager
    include Agents::DSLMethods
    include Agents::LLMBuilder

    attr_reader :llm, :tools, :memory, :thoughts_memory, :engine, :instructions

    # Initialize a new Agent instance
    # @param memory [Memory, Array, nil] The memory instance to use (defaults to new Memory)
    #   Can be a Memory instance or an Array of message hashes
    # @param engine [Class] The engine class to use (defaults to Engine::React)
    # @param options [Hash] Configuration options
    # @option options [Integer] :max_iterations Maximum iterations for reasoning
    # @option options [Integer] :timeout Timeout in seconds for operations
    # @option options [Symbol] :provider LLM provider override
    # @option options [String] :model LLM model override
    # @option options [String] :api_key LLM API key override
    def initialize(memory: nil, engine: Engines::React, **options)
      @memory = initialize_memory(memory)
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
      @max_iterations = options.fetch(:max_iterations) { self.class._max_iterations || 10 }
      @timeout = options.fetch(:timeout) { self.class._timeout || 30 }
      @instructions = options.fetch(:instructions) { self.class._instructions }
    end

    # Run the agent with the given input
    # @param input [String] The input query or task
    # @yield [event] Optional block to handle events during execution
    # @return [Result] The result of the agent's reasoning
    def run(input, &)
      validate_input(input)
      execute_reasoning(input, &)
    rescue ArgumentError
      raise # Re-raise ArgumentError without handling
    rescue StandardError => e
      handle_error(e, input)
    end

    private

    # Initialize memory from various input formats
    # @param memory [Memory, Array, nil] The memory input
    # @return [Memory] The initialized memory instance
    def initialize_memory(memory)
      case memory
      when Memory
        memory
      when Array
        Memory.new(memory)
      when nil
        Memory.new
      else
        raise ArgumentError, "Invalid memory type: #{memory.class}. Expected Memory, Array, or nil"
      end
    end

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
      engine_instance = @engine.new(self, @llm, @tools, @max_iterations, @instructions)
      with_retry { engine_instance.reason(input, &) }
    end

    # Finalize the result by updating memories and running hooks
    # @param input [String] The original input
    # @param result [Result] The result to finalize
    def finalize_result(input, result)
      update_memories(input, result)
      run_hooks(:after_action, result)
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
