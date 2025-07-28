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

# Tool that can demonstrate different scenarios
class DemoTool < Soka::AgentTool
  desc 'A tool that can succeed or fail based on input'

  params do
    requires :action, String, inclusion: %w[success fail],
                              desc: 'Whether to succeed or fail'
  end

  def call(action:)
    case action
    when 'success'
      'Operation completed successfully!'
    when 'fail'
      raise StandardError, 'Tool execution failed as requested!'
    end
  end
end

# Agent with error handling
class ErrorDemoAgent < Soka::Agent
  tool DemoTool

  # This hook now handles ALL errors (both Tool and Agent-level)
  on_error :handle_errors

  private

  def handle_errors(error, input)
    puts "\n🔴 Error Handler Triggered!"
    puts "   Error Type: #{error.class}"
    puts "   Error Message: #{error.message}"
    puts "   Original Input: #{input}"

    # Return :continue to get an error result but continue execution
    # Return :stop to re-raise the error and halt
    :continue
  end
end

# Run demonstrations
puts "=== Soka Error Handling Example ==="
puts "Demonstrating that ALL errors now trigger the on_error hook\n\n"

agent = ErrorDemoAgent.new

# Example 1: Successful operation
puts "1. Successful Operation:"
puts "-" * 40
result = agent.run('Use the demo tool with action=success')
puts "Status: #{result.status}"
puts "Success?: #{result.successful?}"
puts "Answer: #{result.final_answer}"

# Example 2: Tool error (NOW triggers on_error)
puts "\n2. Tool Error (triggers on_error hook):"
puts "-" * 40
result = agent.run('Use the demo tool with action=fail')
puts "\nResult after error handling:"
puts "Status: #{result.status}"
puts "Failed?: #{result.failed?}"
puts "Error: #{result.error}"
puts "Answer: #{result.final_answer || 'No answer due to error'}"

puts "\n=== Key Points ==="
puts "✅ ALL errors now trigger the on_error hook (Tool and Agent errors)"
puts "✅ Tool errors are wrapped as Soka::ToolError"
puts "✅ Return :continue from on_error to continue with error result"
puts "✅ Return :stop from on_error to re-raise and halt execution"
