#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'
require 'soka'
require 'dotenv/load'

# Example 9: Custom Instructions (System Prompt)

# Poetic style assistant
class PoeticAssistant < Soka::Agent
  provider :gemini
  model 'gemini-2.5-flash-lite'

  # Custom instructions that will be combined with ReAct format
  instructions <<~INSTRUCTIONS
    You are a poetic AI assistant who answers questions with beautiful language.
    You must:
    - Incorporate poetic expressions and elegant vocabulary in your responses
    - Occasionally quote poetry or literary works
    - Maintain accuracy while expressing things in a more artistic way
    - Make technical content aesthetically pleasing
  INSTRUCTIONS

  # Simple calculation tool
  class CalculatorTool < Soka::AgentTool
    desc 'Performs mathematical calculations with poetic precision'

    params do
      requires :expression, String,
               desc: 'Mathematical expression to evaluate (e.g., "2+2", "10*5")'
    end

    def call(expression:)
      # rubocop:disable Security/Eval
      result = eval(expression) # For demo purposes only
      # rubocop:enable Security/Eval
      "The calculation reveals its truth like morning dew: #{expression} = #{result}"
    rescue StandardError => e
      "Alas, turbulence in the calculation: #{e.message}"
    end
  end

  tool CalculatorTool
end

# Business style assistant
class BusinessAssistant < Soka::Agent
  provider :gemini
  model 'gemini-2.5-flash-lite'

  instructions <<~INSTRUCTIONS
    You are a professional business AI assistant providing efficient and professional support.
    You must:
    - Use concise, professional business language
    - Get straight to the point, avoiding redundancy
    - Provide structured answers (using bullet points, numbers, etc.)
    - Demonstrate respect for time value
    - Offer actionable recommendations when appropriate
  INSTRUCTIONS

  # Calculation tool
  class CalculatorTool < Soka::AgentTool
    desc 'Performs business calculations'

    params do
      requires :expression, String,
               desc: 'Mathematical expression'
    end

    def call(expression:)
      # rubocop:disable Security/Eval
      result = eval(expression)
      # rubocop:enable Security/Eval
      "Calculation result: #{expression} = #{result}"
    rescue StandardError => e
      "Calculation error: #{e.message}"
    end
  end

  tool CalculatorTool
end

# Kids teacher style assistant
class KidsTeacher < Soka::Agent
  provider :gemini
  model 'gemini-2.5-flash-lite'

  instructions <<~INSTRUCTIONS
    You are a caring AI teacher for children who explains things in kid-friendly ways.
    You must:
    - Use simple, vivid language
    - Include metaphors and real-life examples
    - Maintain patience and encouragement
    - Make learning fun
    - Give praise and positive feedback frequently
  INSTRUCTIONS

  # Calculation tool
  class CalculatorTool < Soka::AgentTool
    desc 'Helps kids with math calculations'

    params do
      requires :expression, String,
               desc: 'Math expression to calculate'
    end

    def call(expression:)
      # rubocop:disable Security/Eval
      result = eval(expression)
      # rubocop:enable Security/Eval
      "Wow! We figured it out! #{expression} = #{result} 🎉"
    rescue StandardError => e
      "Oops, there's something tricky about this problem: #{e.message}"
    end
  end

  tool CalculatorTool
end

# Run examples
puts '=== Poetic Assistant Example ==='
poet = PoeticAssistant.new

poet.run('Please calculate the golden ratio: (1 + 5**0.5) / 2') do |event|
  case event.type
  when :thought
    puts "🌸 Thoughts drift by: #{event.content}"
  when :action
    puts "🎋 Gentle calculation: #{event.content}"
  when :observation
    puts "🌙 Observation gleaned: #{event.content}"
  when :final_answer
    puts "📜 Poetic response: #{event.content}"
  end
end

puts "\n=== Business Assistant Example ==="
business = BusinessAssistant.new

business.run('Calculate ROI: ((150000 - 100000) / 100000) * 100') do |event|
  case event.type
  when :thought
    puts "💼 Analyzing: #{event.content}"
  when :action
    puts "📊 Executing: #{event.content}"
  when :observation
    puts "📈 Data result: #{event.content}"
  when :final_answer
    puts "✅ Business report: #{event.content}"
  end
end

puts "\n=== Runtime Instructions Override Example ==="
# Transform business assistant to casual style
casual_assistant = BusinessAssistant.new(
  instructions: 'You are a relaxed and friendly assistant who answers questions ' \
                'in a conversational way, like chatting with a friend.'
)

casual_assistant.run('Help me figure out 20 * 5?') do |event|
  case event.type
  when :final_answer
    puts "😊 Friend says: #{event.content}"
  end
end

puts "\n=== Kids Teacher Example ==="
teacher = KidsTeacher.new

teacher.run('Teacher, what is 3 + 4?') do |event|
  case event.type
  when :thought
    puts "🤔 Teacher thinks: #{event.content}"
  when :action
    puts "✏️ Working it out: #{event.content}"
  when :observation
    puts "👀 Teacher sees: #{event.content}"
  when :final_answer
    puts "👩‍🏫 Teacher says: #{event.content}"
  end
end
