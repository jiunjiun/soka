#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'
require 'soka'
require 'dotenv/load'
require 'singleton'

# Configure Soka
Soka.setup do |config|
  config.ai do |ai|
    ai.provider = :gemini
    ai.model = 'gemini-2.5-flash-lite'
    ai.api_key = ENV.fetch('GEMINI_API_KEY', nil)
  end

  config.performance do |perf|
    perf.max_iterations = 10
    perf.timeout = 30
  end
end

# Calculator tool - Simple math calculations
class CalculatorTool < Soka::AgentTool
  desc 'Perform basic math operations'

  params do
    requires :expression, String, desc: "Mathematical expression, e.g., '2 + 2' or '10 * 5'"
  end

  def call(expression:)
    # Simple math expression evaluation (production should use safer methods)
    result = eval(expression) # rubocop:disable Security/Eval
    "Calculation result: #{expression} = #{result}"
  rescue StandardError => e
    "Calculation error: #{e.message}"
  end
end

# Shared memory manager
class SharedMemory
  include Singleton

  def initialize
    @storage = {}
  end

  def store(key, value)
    @storage[key] = value
  end

  def retrieve(key)
    @storage[key]
  end

  def exists?(key)
    @storage.key?(key)
  end
end

# Memory tool - Store and retrieve information
class MemoryTool < Soka::AgentTool
  desc 'Remember important information'

  params do
    requires :key, String, desc: 'Information key'
    requires :value, String, desc: 'Content to remember'
  end

  def call(key:, value:)
    SharedMemory.instance.store(key, value)
    "Remembered: #{key} = #{value}"
  end
end

# Recall tool - Retrieve previously remembered information
class RecallTool < Soka::AgentTool
  desc 'Recall previously remembered information'

  params do
    requires :key, String, desc: 'Information key to recall'
  end

  def call(key:)
    if SharedMemory.instance.exists?(key)
      value = SharedMemory.instance.retrieve(key)
      "Recalled: #{key} = #{value}"
    else
      "No memory found for '#{key}'"
    end
  end
end

# Define Agent
class MemoryAgent < Soka::Agent
  tool CalculatorTool
  tool MemoryTool
  tool RecallTool
end

# Main program
puts '=== Soka Memory Example ==='
puts "Testing Agent memory functionality\n\n"

# Program starts

# Method 1: Using Soka::Memory class
puts '>>> Method 1: Using Soka::Memory class'
soka_memory = Soka::Memory.new
soka_memory.add(role: 'user', content: 'My name is Xiao Ming, I am 25 years old')
soka_memory.add(role: 'assistant', content: 'Nice to meet you, Xiao Ming! I will remember that you are 25 years old.')

# Method 2: Using Array (direct format)
puts '>>> Method 2: Using Array (direct format)'
memory_array = [{
  role: 'user',
  content: 'My name is Xiao Ming, I am 25 years old'
}, {
  role: 'assistant',
  content: 'Nice to meet you, Xiao Ming! I will remember that you are 25 years old.'
}]

# Both methods work - Soka will convert Array to Memory object automatically
memory = soka_memory  # You can use either initial_memory_obj or initial_memory_array

# Example of using array format (uncomment to use this instead)
# memory = memory_array

# Test case 1: Basic calculation and memory
puts '\nTest 1: Basic calculation and memory'
# Agent with initial memory
agent_with_memory = MemoryAgent.new(memory: memory)
result = agent_with_memory.run(
  "Please calculate 15 * 8, and remember this calculation result with key 'first_calc'"
)
puts "Agent: #{result.final_answer}"
puts "Confidence: #{(result.confidence_score * 100).round(1)}%"
puts "Iterations: #{result.iterations}"
puts '-' * 50

# Test case 2: Recall previous information
puts "\nTest 2: Recall previous calculation"
# Continue using the same agent, as it already has memory
result = agent_with_memory.run(
  "Please recall what the value of 'first_calc' is?"
)
puts "Agent: #{result.final_answer}"
puts '-' * 50

# Test case 3: Use remembered information for new calculations
puts "\nTest 3: Complex memory operations"
result = agent_with_memory.run(
  "Please remember that pi is 3.14159, then calculate the area of a circle with radius 5 (using pi * r * r), and remember the result as 'circle_area'"
)
puts "Agent: #{result.final_answer}"
puts '-' * 50

# Test case 4: Recall information from initial memory
puts "\nTest 4: Recall initial information"
result = agent_with_memory.run(
  'Do you remember my name and age?'
)
puts "Agent: #{result.final_answer}"
puts '-' * 50

# Display complete conversation history
puts "\n=== Complete Conversation History ==="
agent_with_memory.memory.messages.each_with_index do |msg, idx|
  puts "#{idx + 1}. [#{msg[:role]}]: #{msg[:content][0..100]}#{'…' if msg[:content].length > 100}"
end

# Display the last thinking process
puts "\n=== Last Thinking Process ==="
if result.thoughts&.any?
  result.thoughts.each_with_index do |thought_item, idx|
    step = thought_item[:step] || (idx + 1)
    content = thought_item[:thought] || thought_item[:content] || ''
    puts "#{step}. #{content[0..200]}#{'…' if content.length > 200}"
  end
else
  puts 'No thinking process recorded'
end
