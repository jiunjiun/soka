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

# Define a simple search tool
class SearchTool < Soka::AgentTool
  desc 'Search the web for information'

  params do
    requires :query, String, desc: 'The query to search for'
  end

  def call(query:)
    puts "SearchTool call: #{query}"
    # This is a simulated search result
    case query.downcase
    when /weather/
      'Today in Taipei: Sunny, Temperature 28°C, Humidity 65%'
    when /news/
      'Today\'s headline: AI technology reaches new milestone'
    else
      "Searching for information about '#{query}'..."
    end
  end
end

# Define time tool
class TimeTool < Soka::AgentTool
  desc 'Get current time and date'

  def call
    puts 'TimeTool call'
    Time.now.strftime('%Y-%m-%d %H:%M:%S')
  end
end

# Define Agent
class DemoAgent < Soka::Agent
  tool SearchTool
  tool TimeTool
end

# Use Agent
agent = DemoAgent.new

puts '=== Soka Demo Agent ==='
puts

# Example 1: Ask about weather
puts 'Question: What\'s the weather like in Taipei today?'
puts '-' * 50

agent.run('What\'s the weather like in Taipei today?') do |event|
  case event.type
  when :thought
    puts "💭 Thinking: #{event.content}"
  when :action
    puts "🔧 Action: Using tool #{event.content[:tool]}"
  when :observation
    puts "👀 Observation: #{event.content}"
  when :final_answer
    puts "✅ Answer: #{event.content}"
  end
end

puts
puts '=' * 50
puts

# Example 2: Ask about time
puts 'Question: What time is it now?'
puts '-' * 50

result = agent.run('What time is it now?')
puts "✅ Answer: #{result.final_answer}"
puts "⏱️  Iterations: #{result.iterations}"
