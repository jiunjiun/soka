# Soka - Ruby ReAct Agent Framework

## Project Overview

Soka is a Ruby AI Agent framework based on the ReAct (Reasoning and Acting) pattern. It supports multiple AI providers (Gemini Studio, OpenAI, Anthropic) and provides an object-oriented tool system and intelligent memory management.

## Core Architecture

### Directory Structure
```
soka/
├── lib/
│   ├── soka.rb                    # Main entry point with Zeitwerk autoloading
│   └── soka/
│       ├── agent.rb               # Agent base class with DSL and execution logic
│       ├── agent_tool.rb          # Tool base class with parameter validation
│       ├── agent_tools/
│       │   └── params_validator.rb # Parameter validation module
│       ├── agents/                # Agent feature modules
│       │   ├── dsl_methods.rb     # DSL method definitions
│       │   ├── hook_manager.rb    # Lifecycle hook management
│       │   ├── llm_builder.rb     # LLM instance construction
│       │   ├── retry_handler.rb   # Retry mechanism
│       │   └── tool_builder.rb    # Tool construction and management
│       ├── configuration.rb       # Global configuration system
│       ├── llm.rb                 # LLM unified interface layer
│       ├── llms/                  # LLM provider implementations
│       │   ├── base.rb           # LLM base class
│       │   ├── concerns/         # Shared functionality modules
│       │   │   ├── response_parser.rb    # Response parsing
│       │   │   └── streaming_handler.rb  # Stream processing
│       │   ├── gemini.rb         # Google Gemini implementation
│       │   ├── openai.rb         # OpenAI implementation
│       │   └── anthropic.rb      # Anthropic implementation
│       ├── engines/              # Reasoning engines
│       │   ├── base.rb          # Engine base class
│       │   ├── concerns/        # Engine shared modules
│       │   │   ├── prompt_template.rb     # Prompt templates
│       │   │   └── response_processor.rb  # Response processing
│       │   ├── react.rb         # ReAct reasoning engine
│       │   └── reasoning_context.rb # Reasoning context management
│       ├── memory.rb             # Conversation memory management
│       ├── thoughts_memory.rb    # Thought process memory
│       ├── result.rb             # Result object encapsulation
│       ├── test_helpers.rb       # RSpec test helpers
│       └── version.rb            # Version definition
├── examples/
│   ├── 1_basic.rb               # Basic usage example
│   ├── 2_event_handling.rb      # Event handling example
│   ├── 3_memory.rb              # Memory usage example
│   ├── 4_hooks.rb               # Lifecycle hooks example
│   ├── 5_error_handling.rb      # Error handling example
│   ├── 6_retry.rb               # Retry mechanism example
│   ├── 7_tool_conditional.rb    # Conditional tools example
│   └── 8_multi_provider.rb      # Multi-provider example
├── spec/                         # RSpec tests
└── test_soka.rb                 # Quick test script
```

## Core Component Descriptions

### 1. Agent System (`agent.rb`)
- Provides DSL for defining AI settings, tool registration, and retry mechanisms
- Supports conditional tool loading (`if:` option)
- Built-in lifecycle hooks (before_action, after_action, on_error)
- Uses `times` loop instead of `loop` for iteration control
- Modular design: functionality separated into concern modules
  - `DSLMethods`: DSL method definitions
  - `HookManager`: Lifecycle hook management
  - `LLMBuilder`: LLM instance construction
  - `RetryHandler`: Retry handling
  - `ToolBuilder`: Tool construction and management

### 2. Tool System (`agent_tool.rb`)
- Grape API-like parameter definition system
- Built-in parameter validation (presence, length, inclusion, format)
- Supports required and optional parameters
- Auto-generates tool description schemas

### 3. ReAct Engine (`engines/react.rb`)
- Implements tagged ReAct flow: `<Thought>`, `<Action>`, `<Observation>`, `<Final_Answer>`
- Uses Struct instead of OpenStruct (Rubocop compliant)
- Automatically manages conversation context and tool execution
- Calculates confidence scores (based on iteration count)
- Uses `ReasoningContext` to manage reasoning state
- Shared modules:
  - `PromptTemplate`: Prompt template management
  - `ResponseProcessor`: Response processing logic

### 4. LLM Integration
- **LLM Unified Interface Layer (`llm.rb`)**
  - Provides unified API interface
  - Supports streaming and non-streaming modes
  - Auto-routes to corresponding provider implementation
- **LLM Provider Implementations (`llms/`)**
  - Gemini: Uses Google Generative AI API, defaults to `gemini-2.5-flash-lite`
  - OpenAI: Supports GPT-4 series, includes streaming capabilities
  - Anthropic: Supports Claude 3 series, handles system prompts
  - Shared modules:
    - `ResponseParser`: Unified response parsing
    - `StreamingHandler`: Stream response handling
- Built-in error handling and retry mechanisms

### 5. Memory System
- `Memory`: Manages conversation history
- `ThoughtsMemory`: Records complete ReAct thought processes
- Supports initial memory loading

## Design Decisions

### 1. Using Zeitwerk Autoloading
- Simplifies require management
- Supports hot reloading (development environment)
- Automatically handles namespaces

### 2. Dry-rb Ecosystem Integration
- `dry-validation`: Powerful parameter validation
- `dry-struct`: Type-safe data structures
- `dry-types`: Type definitions and coercion

### 3. Configuration System Design
- Supports global configuration and instance-level overrides
- Block-style DSL provides intuitive configuration
- Fallback mechanism ensures service availability
- Configuration includes AI providers and performance settings

### 4. Error Handling Strategy
- Layered error class inheritance
- Tool execution errors don't interrupt entire flow
- Configurable retry mechanism (exponential backoff)

## Testing Strategy

### Unit Tests
- Using RSpec 3
- Provides `TestHelpers` module for mocking AI responses
- Supports tool mocking and error simulation

### Integration Tests
- `test_soka.rb`: Quick test without real API keys
- `examples/1_basic.rb`: Actual API integration test

## Development Guide

### Adding New AI Provider
1. Create new file in `lib/soka/llms/`
2. Inherit from `Soka::LLMs::Base`
3. Implement required methods:
   - `default_model`
   - `base_url`
   - `chat(messages, **params)`
   - `parse_response(response)`
4. Add new provider to `LLM#create_provider` method

### Adding New Tools
1. Inherit from `Soka::AgentTool`
2. Use `desc` to define description
3. Use `params` block to define parameters
4. Implement `call` method

### Custom Engines
1. Inherit from `Soka::Engines::Base`
2. Implement `reason(task, &block)` method
3. Use `emit_event` to send events
4. Return result object inheriting from Struct
5. Can use concerns modules to share functionality

## Rubocop Compatibility
- Complies with Ruby 3.0+ standards
- Major issues fixed:
  - Using `Struct` instead of `OpenStruct`
  - Using `format` instead of `String#%`
  - Using `times` instead of `loop`
  - Removed unused MODELS constants

## Performance Considerations
- Maximum iteration limit (default 10)
- Request timeout settings (default 30 seconds)
- Memory usage optimization (lazy loading)

## Security
- API keys managed through environment variables
- Input parameter validation
- Error messages don't leak sensitive information
- Supports `.env` files (not version controlled)
- Unified error handling hierarchy

## Future Extensions
- [ ] Support more LLM providers (Cohere, Hugging Face)
- [ ] Implement caching mechanism
- [ ] Support vector database integration
- [ ] Add more built-in tools
- [ ] WebSocket support for real-time conversations
- [ ] Support functional tools (use methods directly as tools)

## Development Standards

### Code Quality Checks
- **When adjusting code, the final step is to run Rubocop to check if the code complies with rules**
- **When Rubocop has any issues, fix them until all rules are satisfied**
- **When adjusting code, the final step is to perform a code review to avoid redundant design and ensure code conciseness**
  - Check for unnecessary intermediate layers or methods
  - Confirm parameter passing is direct and clear
  - Remove duplicate code
  - Avoid over-abstraction

### Code Documentation
- **When adjusting code, add comments and documentation to methods**
  - Use YARD format comments
  - Include method purpose descriptions
  - Explain parameter types and purposes
  - Explain return value types and meanings
  - For complex logic, add implementation detail explanations