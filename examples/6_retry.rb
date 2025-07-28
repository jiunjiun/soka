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

# Flaky API tool that fails randomly
class FlakyApiTool < Soka::AgentTool
  desc 'Call unreliable API'

  params do
    requires :action, String, desc: 'Action to perform'
  end

  def initialize
    super
    @call_count = 0
  end

  def call(action:)
    @call_count += 1
    puts "  🔄 API call attempt ##{@call_count} for: #{action}"
    
    # Fail 60% of the time on first 2 attempts
    if @call_count <= 2 && rand < 0.6
      raise StandardError, "Network timeout on attempt #{@call_count}"
    end
    
    "Success: #{action} completed after #{@call_count} attempts"
  end
end

# Rate limited tool
class RateLimitedTool < Soka::AgentTool
  desc 'API with rate limiting'

  params do
    requires :query, String, desc: 'Query to execute'
  end

  def initialize
    super
    @last_call = Time.now - 10
  end

  def call(query:)
    time_since_last = Time.now - @last_call
    
    if time_since_last < 1
      raise StandardError, 'Rate limit exceeded. Please wait 1 second between calls.'
    end
    
    @last_call = Time.now
    "Query result for: #{query}"
  end
end

# Agent with retry configuration
class RetryAgent < Soka::Agent
  tool FlakyApiTool
  tool RateLimitedTool
  
  # The framework has built-in retry with exponential backoff
end

# Agent with custom configuration
class CustomRetryAgent < Soka::Agent
  tool FlakyApiTool
  
  # Configure max iterations (which affects retry behavior)
  max_iterations 2
end

# Main program
puts '=== Soka Retry Example ==='
puts "Demonstrating retry mechanisms\n\n"

# Example 1: Basic retry with exponential backoff
puts 'Example 1: Retry with exponential backoff'
puts '-' * 50

agent = RetryAgent.new
puts "Calling flaky API (may fail and retry)..."

result = agent.run('Call the flaky API to fetch user data')
puts "\nFinal result: #{result.final_answer}"
puts "Success after retries: #{!result.failed?}"

puts "\n" + '=' * 50 + "\n"

# Example 2: Simple retry configuration
puts 'Example 2: Simple retry configuration'
puts '-' * 50

simple_agent = CustomRetryAgent.new
puts "Using simple retry (max 2 attempts)..."

# Reset the tool's call count
simple_agent.tools.first.instance_variable_set(:@call_count, 0)

result = simple_agent.run('Perform critical operation')
puts "\nResult: #{result.final_answer}"

puts "\n" + '=' * 50 + "\n"

# Example 3: Rate limiting with retry
puts 'Example 3: Handling rate limits'
puts '-' * 50

agent = RetryAgent.new
puts "Making rapid API calls (will hit rate limit)..."

queries = ['Query 1', 'Query 2', 'Query 3']
queries.each do |query|
  puts "\nExecuting: #{query}"
  result = agent.run("Use the rate limited API for: #{query}")
  puts "Result: #{result.final_answer[0..50]}..."
  sleep(0.5) # Small delay between queries
end

puts "\n" + '=' * 50 + "\n"

# Example 4: No retry configuration
puts 'Example 4: Agent without retry (for comparison)'
puts '-' * 50

class NoRetryAgent < Soka::Agent
  tool FlakyApiTool
end

no_retry_agent = NoRetryAgent.new
puts "Calling flaky API without retry..."

begin
  # Reset call count
  no_retry_agent.tools.first.instance_variable_set(:@call_count, 0)
  result = no_retry_agent.run('Try once without retry')
  puts "Success on first try!"
rescue => e
  puts "Failed immediately: #{e.message}"
end

puts "\n=== Retry Benefits ==="
puts "1. Handles transient network failures"
puts "2. Deals with rate limiting gracefully"
puts "3. Improves reliability of AI agents"
puts "4. Configurable backoff strategies"
puts "5. Selective retry based on error types"

puts "\n=== Retry Strategies ==="
puts "1. Fixed delay: Wait same time between retries"
puts "2. Exponential backoff: Increasing delays (1s, 2s, 4s...)"
puts "3. Linear backoff: Linear increase (1s, 2s, 3s...)"
puts "4. Custom logic: Define your own retry behavior"