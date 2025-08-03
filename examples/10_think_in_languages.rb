# frozen_string_literal: true

require_relative '../lib/soka'
require 'dotenv/load'
require 'dentaku'

# Example 10: Think In Languages Feature
#
# This example demonstrates the think_in feature that allows Agents to use
# a specific language for their internal reasoning process.
#
# Key concepts:
# - think_in specifies the language for internal thoughts
# - Final answers typically match the user's input language
# - Default thinking language is 'en' (English)
# - No automatic language detection - you must specify explicitly
#
# Benefits:
# - Improved reasoning quality for specific languages
# - Better cultural context understanding
# - Consistent reasoning patterns across teams
# - Reduced API calls (no language detection)

# Example: Multilingual Agent with configurable thinking language
class MultilingualAgent < Soka::Agent
  provider ENV.fetch('AGENT_PROVIDER', :gemini).to_sym
  model ENV.fetch('AGENT_MODEL', nil)
  
  # Define a simple calculator tool
  class CalculateTool < Soka::AgentTool
    desc 'Perform mathematical calculations'
    
    params do
      requires :expression, String, desc: 'Mathematical expression to evaluate'
    end
    
    def call(expression:)
      calculator = Dentaku::Calculator.new
      result = calculator.evaluate(expression)
      "The result of #{expression} is #{result}"
    rescue StandardError => e
      "Error calculating: #{e.message}"
    end
  end
  
  tool CalculateTool
end

puts "=== Think In Languages Example ==="
puts

# Example 1: Default behavior - thinks in English
# Without specifying think_in, the agent defaults to English thinking
# but still understands and responds appropriately to Chinese input
puts "1. Chinese Input (Default English thinking):"
agent = MultilingualAgent.new  # No think_in specified, defaults to 'en'
result = agent.run("幫我計算 123 + 456 的結果")
puts "Answer: #{result.final_answer}"
puts

# Example 2: Explicit Japanese thinking
# Specifying think_in='ja-JP' makes the agent think in Japanese
# This can improve reasoning quality for Japanese cultural contexts
puts "2. English Input with Japanese Thinking:"
agent = MultilingualAgent.new(think_in: 'ja-JP')
result = agent.run("Calculate the sum of 789 and 321")
puts "Answer: #{result.final_answer}"
puts

# Example 3: DSL configuration for Korean thinking
# Using the DSL to set think_in at the class level
# All instances of KoreanAgent will think in Korean by default
puts "3. DSL Configuration (Korean thinking):"
class KoreanAgent < MultilingualAgent
  think_in 'ko-KR'  # Class-level configuration
end

agent = KoreanAgent.new
result = agent.run("What is 1000 minus 250?")
puts "Answer: #{result.final_answer}"
puts

# Example 4: Show the thinking process
puts "4. Showing Thinking Process:"
agent = MultilingualAgent.new(think_in: 'zh-TW')
result = agent.run("請計算 50 乘以 8") do |event|
  case event.type
  when :thought
    puts "思考: #{event.content}"
  when :action
    puts "行動: 使用工具 #{event.content[:tool]}"
  when :observation
    puts "觀察: #{event.content}"
  when :final_answer
    puts "最終答案: #{event.content}"
  end
end
puts

# Example 5: Multiple languages in sequence
puts "5. Multiple Languages:"
languages = {
  'en' => "Calculate 100 divided by 4",
  'zh-TW' => "請計算 100 除以 4",
  'ja-JP' => "100を4で割った結果を計算してください",
  'es' => "Calcula 100 dividido por 4"
}

languages.each do |lang, question|
  agent = MultilingualAgent.new(think_in: lang)
  result = agent.run(question)
  puts "#{lang}: #{result.final_answer}"
end