# Soka

<p align="center">
  <strong>Ruby AI Agent Framework based on ReAct Pattern</strong>
</p>

<p align="center">
  <a href="#features">Features</a> •
  <a href="#installation">Installation</a> •
  <a href="#quick-start">Quick Start</a> •
  <a href="#advanced-features">Advanced Features</a> •
  <a href="#api-documentation">API Documentation</a> •
  <a href="#examples">Examples</a> •
  <a href="#contributing">Contributing</a>
</p>

Soka is a Ruby AI Agent framework based on the ReAct (Reasoning and Acting) pattern, supporting multiple AI providers, offering an object-oriented tool system and intelligent memory management. It enables you to quickly build intelligent agents that handle complex reasoning and action tasks.

## Features

- 🤖 **Multi AI Provider Support**: Google Gemini, OpenAI, Anthropic
- 🛠️ **Object-Oriented Tool System**: Grape API-like parameter definition and validation
- 🧠 **Intelligent Memory Management**: Conversation history and thought process recording
- 🔄 **ReAct Reasoning Pattern**: Tagged thought-action-observation loop
- ⚡ **Flexible Configuration System**: Global and instance-level configuration options
- 🔁 **Error Handling and Retry**: Built-in exponential backoff retry mechanism
- 🧪 **Test Friendly**: Complete test helper tools
- 📝 **Full Type Support**: Using dry-rb ecosystem
- 🚀 **Modular Design**: Easy to extend and maintain
- 💾 **Built-in Caching Mechanism**: Improve performance and save costs

## Installation

Add the following to your Gemfile:

```ruby
gem 'soka'
```

Then execute:

```bash
bundle install
```

Or install directly:

```bash
gem install soka
```

## Quick Start

### 1. Set up API Key

```bash
# Method 1: Environment variable
export GEMINI_API_KEY="your-api-key"

# Method 2: Create .env file
echo "GEMINI_API_KEY=your-api-key" > .env
```

Get API Keys:
- [Google AI Studio](https://aistudio.google.com/app/apikey)
- [OpenAI Platform](https://platform.openai.com/api-keys)
- [Anthropic Console](https://console.anthropic.com/settings/keys)

### 2. Basic Usage

```ruby
require 'soka'

# Create a simple time tool
class TimeTool < Soka::AgentTool
  desc "Get current time"

  def call
    Time.now.strftime('%Y-%m-%d %H:%M:%S')
  end
end

# Create Agent
class SimpleAgent < Soka::Agent
  tool TimeTool
end

# Execute
agent = SimpleAgent.new
result = agent.run("What time is it?")
puts result.final_answer
```

### 3. Run Examples

```bash
# Run full example (API key required)
ruby examples/1_basic.rb
```

## Core Concepts

### Global Configuration

```ruby
Soka.setup do |config|
  # AI Configuration
  config.ai do |ai|
    ai.provider = :gemini  # :gemini, :openai, :anthropic
    ai.model = 'gemini-2.5-flash-lite'
    ai.api_key = ENV['GEMINI_API_KEY']
  end

  # Performance Configuration
  config.performance do |perf|
    perf.max_iterations = 10      # ReAct max iterations
    perf.timeout = 30             # API call timeout (seconds)
  end

  # Default tools
  config.tools = [SearchTool, TimeTool]
end
```

### Defining Tools

Tools are functional modules that Agents can use:

```ruby
class SearchTool < Soka::AgentTool
  desc "Search the web for information"

  params do
    requires :query, String, desc: "The query to search for"
    optional :location, String, desc: "Location context", default: "Global"

    # Parameter validation
    validates :query, presence: true, length: { minimum: 1, maximum: 500 }
    validates :location, inclusion: { in: %w[Global US Europe Asia] }, allow_nil: true
  end

  def call(query:, location: "Global")
    # Actual search logic
    perform_search(query, location)
  rescue => e
    { error: e.message, tool: self.class.name }
  end

  private

  def perform_search(query, location)
    # Here you can call real search APIs
    "Search results for #{query} in #{location}..."
  end
end
```

### Defining Agents

Agents are the entities that perform ReAct reasoning:

```ruby
class WeatherAgent < Soka::Agent
  # AI settings (override global settings)
  provider :gemini
  model 'gemini-2.5-flash-lite'
  max_iterations 10
  timeout 30

  # Register tools
  tool SearchTool
  tool TimeTool

  # Conditional tool registration
  tool CalculatorTool, if: -> { ENV['ENABLE_CALCULATOR'] == 'true' }

  # Batch registration
  tools SearchTool, TimeTool, WeatherTool

  # Custom tool (functional) - requires description as second parameter
  tool :get_weather, "Get weather for a location"

  # Lifecycle hooks
  before_action :track_action
  after_action :update_metrics
  on_error :handle_error

  private

  # Method implementation for functional tool
  # Note: This is currently experimental and not fully implemented
  def get_weather(location:)
    "#{location} is currently sunny, temperature 25°C"
  end

  def track_action(action)
    # Track action execution
    @action_count ||= 0
    @action_count += 1
  end

  def update_metrics(result)
    # Update metrics
    # metrics.record(result)
  end

  def handle_error(error, context)
    # Handle errors
    :continue  # or :stop to interrupt execution
  end
end
```

### Using Agents

#### Block Mode (Real-time Feedback)

Suitable for scenarios that need to display the execution process:

```ruby
agent = WeatherAgent.new

agent.run('What is the weather in Tokyo today?') do |event|
  case event.type
  when :thought
    puts "💭 Thinking: #{event.content}"
  when :action
    puts "🔧 Action: Using tool #{event.content[:tool]}"
  when :observation
    puts "👀 Observation: #{event.content}"
  when :final_answer
    puts "✅ Answer: #{event.content}"
  when :error
    puts "❌ Error: #{event.content}"
  end
end
```

#### Direct Mode (Get Result)

Suitable for scenarios that only need the final result:

```ruby
agent = WeatherAgent.new
result = agent.run('What is the weather in Tokyo today?')

# Result object provides rich information
puts result.final_answer      # Final answer
puts result.confidence_score  # Confidence score (0.0-1.0)
puts result.iterations       # Number of iterations used
puts result.status          # :success, :failed, :timeout, :max_iterations_reached
puts result.execution_time  # Execution time (if recorded)

# Check execution status
if result.successful?
  puts "Success: #{result.final_answer}"
elsif result.failed?
  puts "Failed: #{result.error}"
elsif result.timeout?
  puts "Execution timeout"
elsif result.max_iterations_reached?
  puts "Max iterations reached"
end
```

### Memory Management

#### Basic Conversation Memory

```ruby
# Initialize Agent with history
memory = [
  { role: 'user', content: 'My name is John' },
  { role: 'assistant', content: 'Hello John! Nice to meet you.' }
]

agent = WeatherAgent.new(memory: memory)
result = agent.run('What is my name?')
# => "Your name is John."

# Memory updates automatically
puts agent.memory
# <Soka::Memory> [
#   { role: 'user', content: 'My name is John' },
#   { role: 'assistant', content: 'Hello John! Nice to meet you.' },
#   { role: 'user', content: 'What is my name?' },
#   { role: 'assistant', content: 'Your name is John.' }
# ]
```

#### Thought Process Memory

```ruby
# View complete thought process
puts agent.thoughts_memory
# <Soka::ThoughtsMemory> (3 sessions, 2 successful, 1 failed, avg confidence: 0.82, avg iterations: 2.3)

# Get detailed information for specific session
last_session = agent.thoughts_memory.last_session
puts last_session[:thoughts]  # All thinking steps
puts last_session[:confidence_score]  # Confidence score for that execution
```

## Advanced Features

### ReAct Flow Format

Soka uses a tagged ReAct format:

```xml
<Thought>I need to search for weather information in Tokyo</Thought>
<Action>
Tool: search
Parameters: {"query": "Tokyo weather", "location": "Japan"}
</Action>
<Observation>Tokyo today: Sunny, temperature 28°C, humidity 65%</Observation>
<Thought>I have obtained the weather information and can answer the user now</Thought>
<Final_Answer>Today in Tokyo it's sunny with a temperature of 28°C and humidity of 65%.</Final_Answer>
```

### Result Object Structure

```ruby
# Result object attributes
result.input            # User input
result.thoughts         # Array of thinking steps
result.final_answer     # Final answer
result.confidence_score # Confidence score (0.0-1.0)
result.status          # Status (:success, :failed, :timeout, :max_iterations_reached)
result.error           # Error message (if any)
result.execution_time  # Execution time (seconds)
result.iterations      # Number of iterations

# Complete structure
{
  input: "User input",
  thoughts: [
    {
      step: 1,
      thought: "Thinking content",
      action: { tool: "search", params: { query: "..." } },
      observation: "Observation result"
    }
  ],
  final_answer: "Final answer",
  confidence_score: 0.85,  # Calculated based on iterations
  status: :success,        # :success, :failed, :timeout, :max_iterations_reached
  error: nil,             # Error message (if any)
  execution_time: 1.23,   # Execution time (seconds)
  iterations: 2,          # Number of iterations
  created_at: Time        # Creation time
}
```

### Test Support

Soka provides complete test helper tools:

```ruby
RSpec.describe WeatherAgent do
  include Soka::TestHelpers

  it "answers weather questions" do
    # Mock AI response
    mock_ai_response({
      thoughts: [
        {
          step: 1,
          thought: "Need to search for weather information",
          action: { tool: "search", params: { query: "Tokyo weather" } },
          observation: "Tokyo is sunny today"
        }
      ],
      final_answer: "Tokyo is sunny today."
    })

    # Mock tool response
    mock_tool_response(SearchTool, "Tokyo is sunny today")

    agent = described_class.new
    result = agent.run("What's the weather in Tokyo?")

    expect(result).to be_successful
    expect(result.final_answer).to include("sunny")
    expect(result).to have_thoughts_count(1)
    expect(result).to have_confidence_score_above(0.8)
  end

  it "handles tool errors gracefully" do
    allow_tool_to_fail(SearchTool, StandardError.new("API error"))

    agent = described_class.new
    result = agent.run("Search test")

    expect(result).to be_failed
    expect(result.error).to include("API error")
  end
end
```

### Custom Engines

You can implement your own reasoning engine:

```ruby
class CustomEngine < Soka::Engines::Base
  def reason(task, &block)
    # Implement custom reasoning logic
    context = Soka::Engines::ReasoningContext.new(
      task: task,
      event_handler: block,
      max_iterations: max_iterations
    )

    # Use emit_event to send events
    emit_event(:thought, "Starting reasoning...", &block)

    # Perform reasoning...

    # Return result (using Struct)
    Soka::Engines::React::ReasonResult.new(
      input: task,
      thoughts: thoughts,
      final_answer: answer,
      status: :success,
      confidence_score: calculate_confidence_score(thoughts, :success)
    )
  end
end

# Use custom engine
agent = MyAgent.new(engine: CustomEngine)
```

## Examples

The `examples/` directory contains several examples demonstrating different features of Soka, ordered from basic to advanced:

### 1. Basic Example (`examples/1_basic.rb`)
Demonstrates the fundamental usage of Soka with simple tools:
- Creating basic tools (SearchTool, TimeTool)
- Setting up an agent
- Running queries with event handling
- Direct result access

### 2. Event Handling (`examples/2_event_handling.rb`)
Shows how to handle real-time events during agent execution:
- Event-based response handling
- Different event types (thought, action, observation, final_answer)
- Multi-step task processing
- Direct result mode vs event mode

### 3. Memory Management (`examples/3_memory.rb`)
Illustrates memory features and conversation context:
- Using Soka::Memory for conversation history
- Array format for initial memory
- Tool-based memory storage and recall
- Accessing complete conversation history
- Viewing thinking processes

### 4. Lifecycle Hooks (`examples/4_hooks.rb`)
Demonstrates lifecycle hooks for monitoring and control:
- `before_action` for pre-processing
- `after_action` for post-processing
- `on_error` for error handling
- Tracking agent activity and metrics

### 5. Error Handling (`examples/5_error_handling.rb`)
Shows robust error handling mechanisms:
- Tool errors and agent-level errors
- Using `on_error` hooks
- Continuing execution after errors
- Error result inspection

### 6. Retry Mechanisms (`examples/6_retry.rb`)
Demonstrates retry strategies for reliability:
- Handling transient failures
- Exponential backoff
- Rate limiting scenarios
- Configuring retry behavior

### 7. Conditional Tools (`examples/7_tool_conditional.rb`)
Shows dynamic tool loading based on conditions:
- Environment-based tool loading
- Role-based access control
- Feature flag integration
- Time-based availability

### 8. Multi-Provider Support (`examples/8_multi_provider.rb`)
Demonstrates using different AI providers:
- Configuring Gemini, OpenAI, and Anthropic
- Provider-specific features
- Comparing outputs across models
- Cost optimization strategies

To run any example:
```bash
# Make sure you have the required API keys in your .env file
ruby examples/1_basic.rb
```

## API Documentation

### Supported AI Providers

#### Google Gemini
- Models: `gemini-2.5-pro`, `gemini-2.5-flash`, `gemini-2.5-flash-lite`
- Environment variable: `GEMINI_API_KEY`
- Features: Fast response, cost-effective
- Default model: `gemini-2.5-flash-lite`

#### OpenAI
- Models: `gpt-4.1`, `gpt-4.1-mini`, `gpt-4.1-nano`
- Environment variable: `OPENAI_API_KEY`
- Features: Streaming support, powerful reasoning

#### Anthropic
- Models: `claude-opus-4-0`, `claude-sonnet-4-0`, `claude-3-5-haiku-latest`
- Environment variable: `ANTHROPIC_API_KEY`
- Features: Long context support, excellent code understanding

### Configuration Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `ai.provider` | Symbol | `:gemini` | AI provider |
| `ai.model` | String | `"gemini-2.5-flash-lite"` | Model to use |
| `ai.api_key` | String | nil | API key |
| `performance.max_iterations` | Integer | 10 | Max iterations |
| `performance.timeout` | Integer | 30 | Timeout (seconds) |

### Tool Parameter Validation

| Validator | Options | Description |
|-----------|---------|-------------|
| `presence` | `true/false` | Value cannot be empty |
| `length` | `minimum`, `maximum` | String length limits |
| `inclusion` | `in`, `allow_nil` | Value must be in specified list |
| `format` | `with` | Match regular expression |

## Performance Optimization

1. **Use appropriate models**:
   - Simple tasks: `gemini-2.5-flash-lite` or `gpt-4.1-mini` or `claude-3-5-haiku-latest`
   - Complex reasoning: `gemini-2.5-pro` or `gpt-4.1` or `claude-sonnet-4-0`

2. **Control iterations**:
   ```ruby
   agent = MyAgent.new(max_iterations: 5)  # Limit iterations
   ```


## Troubleshooting

### Common Issues

1. **API Key Error**
   ```
   Soka::LLMError: API key is required
   ```
   Solution: Ensure correct environment variable is set or provide API key in configuration

2. **Timeout Error**
   ```
   Soka::LLMError: Request timed out
   ```
   Solution: Increase timeout or use a faster model

3. **Max Iterations Reached**
   ```
   Status: max_iterations_reached
   ```
   Solution: Simplify the problem or increase `max_iterations`

### Debugging Tips

```ruby
# Adjust max iterations
Soka.configure do |c|
  c.performance.max_iterations = 20
end

# Use block mode to see execution process
agent.run(query) do |event|
  p event  # Print all events
end

# Inspect thought process
result = agent.run(query)
result.thoughts.each do |thought|
  puts "Step #{thought[:step]}: #{thought[:thought]}"
  puts "Action: #{thought[:action]}" if thought[:action]
  puts "Observation: #{thought[:observation]}" if thought[:observation]
end
```

## Development

```bash
# Install dependencies
bundle install

# Run tests
bundle exec rspec

# Run Rubocop
bundle exec rubocop

# Open interactive console
bin/console

# Create new version
# 1. Update lib/soka/version.rb
# 2. Update CHANGELOG.md
# 3. Commit changes
# 4. Create tag
bundle exec rake release
```

## Contributing

We welcome all forms of contributions!

1. Fork the project
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

Please ensure:
- Add appropriate tests
- Update relevant documentation
- Follow existing code style
- Pass Rubocop checks

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Thanks to the [ReAct paper](https://arxiv.org/abs/2210.03629) for the theoretical foundation
- Thanks to the [Regent](https://github.com/alextwoods/regent) project for architectural inspiration
- Thanks to all contributors for their efforts

---

<p align="center">
  Made with ❤️ in Taiwan<br>
  Created by <a href="https://claude.ai/code">Claude Code</a>
</p>
