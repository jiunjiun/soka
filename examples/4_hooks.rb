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
end

# Simple database tool
class DatabaseTool < Soka::AgentTool
  desc 'Query database'

  params do
    requires :query, String, desc: 'SQL query to execute'
  end

  def call(query:)
    # Simulated database query
    if query.downcase.include?('select')
      "Found 5 records matching your query"
    else
      "Query executed successfully"
    end
  end
end

# Agent with hooks
class HookedAgent < Soka::Agent
  tool DatabaseTool

  # Hook called before action
  before_action :log_request
  
  # Hook called after action
  after_action :log_response
  
  # Hook called on error
  on_error :handle_error

  private

  def log_request(input)
    puts "🔵 [BEFORE] Starting request: #{input}"
    puts "🔵 [BEFORE] Memory size: #{@memory.messages.size} messages"
    puts "🔵 [BEFORE] Available tools: #{@tools.map { |t| t.class.name }.join(', ')}"
    puts '-' * 50
  end

  def log_response(result)
    puts '-' * 50
    puts "🟢 [AFTER] Request completed"
    puts "🟢 [AFTER] Final answer: #{result.final_answer[0..100]}..."
    puts "🟢 [AFTER] Iterations: #{result.iterations}"
    puts "🟢 [AFTER] Confidence: #{(result.confidence_score * 100).round(1)}%"
    puts "🟢 [AFTER] Memory size: #{@memory.messages.size} messages"
  end

  def handle_error(error, input)
    puts "🔴 [ERROR] An error occurred!"
    puts "🔴 [ERROR] Input: #{input}"
    puts "🔴 [ERROR] Error: #{error.message}"
    puts "🔴 [ERROR] Backtrace: #{error.backtrace.first(3).join("\n")}"
    
    # Return :continue to continue execution with error result
    # Return :stop to re-raise the error
    :continue
  end
end

# Main program
puts '=== Soka Hooks Example ==='
puts "Demonstrating lifecycle hooks\n\n"

agent = HookedAgent.new

# Example 1: Normal execution with hooks
puts 'Example 1: Normal execution showing all hooks'
puts '=' * 50

result = agent.run('Query the database for user statistics')
puts "\nResult: #{result.final_answer}" if result.respond_to?(:final_answer)

puts "\n" + '=' * 50 + "\n"

# Example 2: Multiple calls showing memory growth
puts 'Example 2: Multiple calls showing memory tracking'
puts '=' * 50

queries = [
  'Select all active users',
  'Count total orders this month',
  'Find top selling products'
]

queries.each_with_index do |query, index|
  puts "\n--- Query #{index + 1} ---"
  agent.run(query)
  sleep(0.5) # Small delay for visibility
end

puts "\n" + '=' * 50 + "\n"

# Example 3: Error handling
puts 'Example 3: Error handling with hooks'
puts '=' * 50

# Create a tool that will trigger an error
class ErrorTool < Soka::AgentTool
  desc 'This tool simulates errors'
  
  def call
    raise StandardError, 'This is a simulated tool error!'
  end
end

class ErrorHandlingAgent < HookedAgent
  tool ErrorTool
end

error_agent = ErrorHandlingAgent.new
result = error_agent.run('Use the error tool to test error handling')
puts "\nError handled gracefully: #{result.failed? ? 'Yes' : 'No'}"
puts "Final answer: #{result.final_answer}" if result.final_answer
puts "Error message: #{result.error}" if result.error

puts "\n=== Hook Benefits ==="
puts "1. Logging and monitoring of agent activity"
puts "2. Pre-processing of inputs before execution"
puts "3. Post-processing of results"
puts "4. Custom error handling and recovery"
puts "5. Performance tracking and metrics"
puts "6. Integration with external systems"