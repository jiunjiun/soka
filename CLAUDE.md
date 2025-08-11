# Soka - Ruby ReAct Agent Framework

## 🎯 What is Soka?

Soka is a Ruby framework for building AI agents using the ReAct (Reasoning and Acting) pattern. It enables your Ruby applications to leverage AI capabilities through a clean, object-oriented interface.

### Key Features
- **Multi-Provider Support**: Works with Gemini, OpenAI, and Anthropic out of the box
- **ReAct Pattern**: Implements structured reasoning with Thought → Action → Observation → Final Answer flow
- **Tool System**: Define custom tools that agents can use to interact with your application
- **Memory Management**: Built-in conversation and thought process tracking
- **Minimal Dependencies**: Only requires `faraday` and `zeitwerk` - no heavy frameworks

## 🚀 Quick Start

```ruby
class MyAgent < Soka::Agent
  provider :gemini
  model 'gemini-2.5-flash-lite'

  tool :calculator, 'Performs math calculations' do
    def call(expression:)
      # Your tool logic here
    end
  end
end

agent = MyAgent.new
result = agent.run("Calculate 123 * 456")
puts result.final_answer
```

## 📁 Project Structure

```
soka/
├── lib/soka/
│   ├── agent.rb                 # Core Agent class with DSL
│   ├── agent_tool.rb            # Base class for tools
│   ├── agents/                  # Agent components (modular design)
│   │   ├── dsl_methods.rb       # DSL for agent configuration
│   │   ├── hook_manager.rb      # Lifecycle hooks
│   │   ├── llm_builder.rb       # LLM instance creation
│   │   ├── retry_handler.rb     # Retry logic
│   │   └── tool_builder.rb      # Tool management
│   ├── engines/                 # Reasoning engines
│   │   ├── react.rb             # ReAct implementation
│   │   └── concerns/            # Shared engine modules
│   ├── llms/                    # AI provider integrations
│   │   ├── gemini.rb            # Google Gemini
│   │   ├── openai.rb            # OpenAI GPT
│   │   └── anthropic.rb         # Anthropic Claude
│   └── memory.rb                # Conversation memory
├── examples/                    # Working examples (1-10)
└── spec/                        # RSpec tests
```

## 🔧 Core Components

### Agent System
The heart of Soka - defines agents with a simple DSL:

```ruby
class MyAgent < Soka::Agent
  provider :gemini              # Choose AI provider
  model 'gemini-2.5-flash-lite' # Specify model
  max_iterations 10              # Limit reasoning cycles

  # Define tools
  tool :my_tool, 'Description' do
    def call(param:)
      # Tool implementation
    end
  end

  # Lifecycle hooks
  before_action { |task| log("Starting: #{task}") }
  after_action { |result| log("Completed: #{result}") }
  on_error { |error| handle_error(error) }
end
```

### Tool System
Create reusable tools with parameter validation:

```ruby
class WeatherTool < Soka::AgentTool
  desc 'Get weather information'

  params do
    requires :location, String, desc: 'City name'
    optional :units, String, inclusion: %w[celsius fahrenheit]
  end

  def call(location:, units: 'celsius')
    # Fetch weather data
    "Weather in #{location}: 22°C, Sunny"
  end
end
```

### ReAct Engine
Implements the reasoning pattern with structured tags:

1. **Thought**: Agent thinks about the task
2. **Action**: Decides which tool to use
3. **Observation**: Receives tool results
4. **Final Answer**: Provides the solution

The engine automatically:
- Manages iteration loops
- Calculates confidence scores
- Handles tool execution
- Tracks reasoning context

### Memory System
Two types of memory for different purposes:

- **Conversation Memory**: Tracks dialogue history
- **Thoughts Memory**: Records complete reasoning processes

```ruby
# Initialize with existing conversation
memory = Soka::Memory.new
memory.add(role: 'user', content: 'Previous question')
memory.add(role: 'assistant', content: 'Previous answer')

agent = MyAgent.new(memory: memory)
```

## 🎨 Advanced Features

### Custom Instructions
Change your agent's personality and response style:

```ruby
class FriendlyAgent < Soka::Agent
  provider :gemini

  # Define personality at class level
  instructions <<~PROMPT
    You are a friendly, helpful assistant.
    Use casual language and be encouraging.
    Add emojis when appropriate.
  PROMPT
end

# Or override at runtime
agent = FriendlyAgent.new(
  instructions: 'Be more formal and professional.'
)
```

### Multilingual Thinking (Think In)
Optimize reasoning for specific languages:

```ruby
class GlobalAgent < Soka::Agent
  provider :gemini

  # Set default thinking language
  think_in 'zh-TW'  # Think in Traditional Chinese
end

# Or set dynamically
agent = GlobalAgent.new(think_in: 'ja-JP')
result = agent.run("Help me with this task")
```

**Key Points:**
- Thinking language affects internal reasoning only
- Responses adapt to user's input language
- Default is English (`'en'`)
- No automatic language detection (explicit setting required)

### Conditional Tools
Load tools based on conditions:

```ruby
class SmartAgent < Soka::Agent
  # Only in development
  tool DebugTool, if: -> { ENV['RAILS_ENV'] == 'development' }

  # Based on user permissions
  tool AdminTool, if: -> { current_user.admin? }

  # Feature flags
  tool BetaFeature, if: -> { feature_enabled?(:beta) }
end
```

## 🛠 Development Guide

### Creating a New AI Provider

1. Create file in `lib/soka/llms/your_provider.rb`
2. Inherit from `Soka::LLMs::Base`
3. Implement required methods:

```ruby
module Soka
  module LLMs
    class YourProvider < Base
      def default_model
        'your-default-model'
      end

      def base_url
        'https://api.yourprovider.com'
      end

      def chat(messages, **params)
        # Make API request
        # Return response
      end

      def parse_response(response)
        # Parse API response
        # Return standardized format
      end
    end
  end
end
```

### Creating Custom Engines

```ruby
class MyEngine < Soka::Engines::Base
  def reason(task, &block)
    # Implement your reasoning logic
    emit_event(:thought, "Thinking about: #{task}")

    # Process and return result
    MyResult.new(
      input: task,
      output: "Processed result",
      status: :success
    )
  end
end
```

## ⚙️ Configuration

### Global Configuration

```ruby
Soka.setup do |config|
  config.ai do |ai|
    ai.provider = :gemini
    ai.model = 'gemini-2.5-flash-lite'
    ai.api_key = ENV['GEMINI_API_KEY']
  end

  config.performance do |perf|
    perf.max_iterations = 10
  end
end
```

### Environment Variables

```bash
# .env file
GEMINI_API_KEY=your_api_key
OPENAI_API_KEY=your_api_key
ANTHROPIC_API_KEY=your_api_key
```

## 📊 Performance & Security

### Performance Tips
- Set appropriate `max_iterations` to prevent infinite loops
- Implement caching for frequently used tools
- Consider memory limits for long conversations

### Security Best Practices
- Never commit API keys to version control
- Use environment variables for sensitive data
- Validate all tool inputs
- Sanitize tool outputs before returning
- Implement rate limiting for production use

## 🧪 Testing

### Unit Testing

```ruby
RSpec.describe MyAgent do
  let(:agent) { described_class.new }

  it 'processes tasks correctly' do
    result = agent.run('Test task')
    expect(result).to be_successful
    expect(result.final_answer).to include('expected')
  end
end
```

### Mocking AI Responses

```ruby
allow(agent).to receive(:llm).and_return(mock_llm)
allow(mock_llm).to receive(:chat).and_return(
  double(content: '<Thought>Test</Thought><Final_Answer>Done</Final_Answer>')
)
```

## 📚 Examples

The `examples/` directory contains 10 comprehensive examples:

1. **Basic Usage** - Simple agent setup and execution
2. **Event Handling** - Responding to agent events
3. **Memory Management** - Using conversation memory
4. **Lifecycle Hooks** - before/after/error handling
5. **Error Handling** - Graceful error management
6. **Retry Logic** - Automatic retry configuration
7. **Conditional Tools** - Dynamic tool loading
8. **Multi-Provider** - Switching between AI providers
9. **Custom Instructions** - Personality customization
10. **Multilingual Thinking** - Language-specific reasoning

## 🔄 Future Roadmap

- [ ] Additional LLM providers (Cohere, Hugging Face)
- [ ] Built-in caching mechanism
- [ ] Vector database integration for RAG
- [ ] More built-in tools (web search, file operations)
- [ ] WebSocket support for real-time streaming
- [ ] Direct method-as-tool support

## 📖 Development Standards

### Code Quality
- Run `bundle exec rubocop` before committing
- Ensure all tests pass with `bundle exec rspec`
- Follow Ruby style guide and conventions
- Keep methods small and focused
- Write clear, self-documenting code

### Code Quality Checks (Important for AI Assistants)
- **When adjusting code, the final step is to run Rubocop to check if the code complies with rules**
- **When Rubocop has any issues, fix them until all rules are satisfied**
- **When adjusting code, the final step is to perform a code review to avoid redundant design and ensure code conciseness**
  - Check for unnecessary intermediate layers or methods
  - Confirm parameter passing is direct and clear
  - Remove duplicate code
  - Avoid over-abstraction

### Ruby Code Organization (Important for AI Assistants)
- **Always organize Ruby class methods with public methods first, then private methods**
  - Place all public methods at the beginning of the class
  - Place all private methods at the end after a single `private` keyword
  - Never mix public and private sections
  - Avoid using `public` keyword explicitly unless switching back from private

### Code Documentation
- **When adjusting code, add comments and documentation to methods**
  - Use YARD format comments
  - Include method purpose descriptions
  - Explain parameter types and purposes
  - Explain return value types and meanings
  - For complex logic, add implementation detail explanations
- Include usage examples in comments
- Document all public APIs
- Keep README and CLAUDE.md updated

### Problem Solving Approach (Important for AI Assistants)
- **Always solve problems directly - never avoid issues or use incorrect workarounds**
  - Face technical challenges head-on without shortcuts or workarounds
  - Ensure solutions align with architecture design and best practices
  - Avoid temporary patches; pursue fundamental solutions
- **When facing difficult problems or needing more information, provide current status and issues, then pause for discussion before implementation**
  - Analyze and explain the situation when encountering complex problems
  - Clearly describe difficulties encountered and information needed
  - Wait for confirmation and discussion before proceeding with implementation
  - Maintain transparent communication without assuming or guessing requirements

## 🤝 Contributing

[Contributing Guidelines]

---

*Built with ❤️ using Ruby and AI*
