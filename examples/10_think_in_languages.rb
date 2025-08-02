# frozen_string_literal: true

require_relative '../lib/soka'
require 'dotenv/load'

# Example of using the think_in feature for multilingual thinking
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
      result = eval(expression)
      "The result of #{expression} is #{result}"
    rescue StandardError => e
      "Error calculating: #{e.message}"
    end
  end
  
  tool CalculateTool
end

puts "=== Think In Languages Example ==="
puts

# Example 1: Chinese thinking
puts "1. Chinese Question (Auto-detect):"
agent = MultilingualAgent.new
result = agent.run("幫我計算 123 + 456 的結果")
puts "Answer: #{result.final_answer}"
puts

# Example 2: Japanese thinking with explicit setting
puts "2. Japanese Question (Explicit):"
agent = MultilingualAgent.new(think_in: 'ja-JP')
result = agent.run("Calculate the sum of 789 and 321")
puts "Answer: #{result.final_answer}"
puts

# Example 3: Korean thinking via DSL
puts "3. Korean Question (DSL):"
class KoreanAgent < MultilingualAgent
  think_in 'ko-KR'
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