#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'
require 'soka'
require 'dotenv/load'

# Configure Soka
Soka.setup do |config|
  config.ai do |ai|
    ai.provider = :gemini
    ai.model = 'gemini-2.5-flash-lite'
    ai.api_key = ENV.fetch('GEMINI_API_KEY', nil)
  end

  config.performance do |perf|
    perf.max_iterations = 5
    perf.timeout = 30
  end
end

# Simple calculation tool
class CalculatorTool < Soka::AgentTool
  desc 'Perform calculations'

  params do
    requires :expression, String, desc: 'Mathematical expression to calculate'
  end

  def call(expression:)
    result = eval(expression) # rubocop:disable Security/Eval
    "Result: #{expression} = #{result}"
  rescue StandardError => e
    "Error: #{e.message}"
  end
end

# Weather tool
class WeatherTool < Soka::AgentTool
  desc 'Get weather information'

  params do
    requires :location, String, desc: 'Location to get weather for'
  end

  def call(location:)
    # Simulated weather data
    "Weather in #{location}: Sunny, 22°C"
  end
end

# Define streaming agent
class StreamingAgent < Soka::Agent
  tool CalculatorTool
  tool WeatherTool
end

# Main program
puts '=== Soka Event Handling Example ==='
puts "Demonstrating event-based responses\n\n"
puts "NOTE: Streaming is not yet fully integrated with the event system\n"

agent = StreamingAgent.new

# Example 1: Event-based response handling
puts 'Example 1: Simple calculation with event handling'
puts '-' * 50

agent.run('Calculate 123 * 456') do |event|
  case event.type
  when :thought
    puts "💭 Thinking: #{event.content}"
  when :action
    puts "🔧 Action: Using #{event.content[:tool]}"
  when :observation
    puts "👀 Result: #{event.content}"
  when :final_answer
    puts "✅ Final: #{event.content}"
  when :error
    puts "❌ Error: #{event.content}"
  end
end

puts "\n" + '=' * 50 + "\n"

# Example 2: Multi-step task with event handling
puts 'Example 2: Multi-step task with event handling'
puts '-' * 50

agent.run('What is the weather in Tokyo? Also calculate 15% tip on $85.50') do |event|
  case event.type
  when :thought
    puts "💭 Thinking: #{event.content}"
  when :action
    puts "🔧 Action: #{event.content[:tool]}"
    puts "   Input: #{event.content[:params]}" if event.content[:params]
  when :observation
    puts "👀 Result: #{event.content}"
  when :final_answer
    puts "✅ Complete: #{event.content}"
  end
end

puts "\n" + '=' * 50 + "\n"

# Example 3: Without event handling (direct result)
puts 'Example 3: Without event handling (direct result)'
puts '-' * 50

result = agent.run('Calculate the area of a circle with radius 5')
puts "Direct result: #{result.final_answer}"
puts "Confidence: #{(result.confidence_score * 100).round(1)}%"
puts "Iterations: #{result.iterations}"

puts "\n=== Event Handling Benefits ==="
puts "1. Real-time feedback on agent's thinking process"
puts "2. Visibility into tool usage and results"
puts "3. Can track progress during complex tasks"
puts "4. Debugging support with detailed event logs"
puts "\nNote: True streaming of LLM responses is not yet integrated with events"
