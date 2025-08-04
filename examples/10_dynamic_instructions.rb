#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'
require 'soka'
require 'dotenv/load'
require 'dentaku'

# Example 10: Dynamic Instructions via Method
# 
# This example demonstrates how to use a method to generate instructions dynamically.
# Instead of static string instructions, you can define a method that returns
# instructions based on runtime conditions.
# 
# Key concepts:
# - Using a Symbol to reference an instructions method
# - Dynamic instruction generation based on context
# - Maintaining compatibility with string-based instructions

# Example 1: Time-aware Assistant
# Instructions change based on time of day
class TimeAwareAssistant < Soka::Agent
  provider :gemini
  model 'gemini-2.5-flash-lite'

  # Use a method to generate instructions
  instructions :generate_time_based_instructions

  class GreetingTool < Soka::AgentTool
    desc 'Generate appropriate greetings'

    params do
      requires :name, String, desc: 'Name of the person to greet'
    end

    def call(name:)
      "Greeting generated for #{name}"
    end
  end

  tool GreetingTool

  private

  def generate_time_based_instructions
    hour = Time.now.hour

    base_instructions = if hour < 12
                          'You are a cheerful morning assistant who is energetic and motivating.'
                        elsif hour < 17
                          'You are a focused afternoon assistant who is professional and efficient.'
                        else
                          'You are a relaxed evening assistant who is calm and supportive.'
                        end

    <<~INSTRUCTIONS
      #{base_instructions}
      Current time: #{Time.now.strftime('%H:%M')}
      
      You must:
      - Acknowledge the time of day in your responses
      - Adjust your tone based on the time period
      - Be helpful while matching the appropriate energy level
    INSTRUCTIONS
  end
end

# Example 2: Environment-based Assistant
# Instructions change based on environment variables
class EnvironmentAwareAssistant < Soka::Agent
  provider :gemini
  model 'gemini-2.5-flash-lite'

  # Use a method for environment-based instructions
  instructions :build_environment_instructions

  class CalculatorTool < Soka::AgentTool
    desc 'Performs calculations'

    params do
      requires :expression, String, desc: 'Math expression'
    end

    def call(expression:)
      calculator = Dentaku::Calculator.new
      result = calculator.evaluate(expression)
      "Result: #{expression} = #{result}"
    rescue StandardError => e
      "Error: #{e.message}"
    end
  end

  tool CalculatorTool

  private

  def build_environment_instructions
    user_level = ENV['USER_LEVEL'] || 'beginner'
    debug_mode = ENV['DEBUG'] == 'true'

    style = case user_level
            when 'expert'
              'Use technical terminology and assume deep knowledge. Be concise.'
            when 'intermediate'
              'Balance technical accuracy with clear explanations. Provide context when needed.'
            else
              'Use simple language and explain concepts thoroughly. Avoid jargon.'
            end

    debug_info = if debug_mode
                   "\n- Include detailed technical information in responses"
                 else
                   "\n- Keep responses focused on the essential information"
                 end

    <<~INSTRUCTIONS
      You are an AI assistant adapting to the user's expertise level.
      
      Communication style: #{style}
      User level: #{user_level}
      Debug mode: #{debug_mode}
      
      Guidelines:#{debug_info}
      - Adapt your responses to the #{user_level} level
      - Maintain accuracy while adjusting complexity
    INSTRUCTIONS
  end
end

# Example 3: Session-based Assistant
# Instructions change based on a session ID
class SessionAssistant < Soka::Agent
  provider :gemini
  model 'gemini-2.5-flash-lite'

  # Use method for session-based instructions
  instructions :generate_session_instructions

  class InfoTool < Soka::AgentTool
    desc 'Provides information'

    params do
      requires :query, String, desc: 'Information query'
    end

    def call(query:)
      "Information about: #{query}"
    end
  end

  tool InfoTool

  private

  def generate_session_instructions
    # Simulate different session types based on time
    session_type = Time.now.min % 3
    
    personality = case session_type
                  when 0
                    'You are a formal, professional assistant.'
                  when 1
                    'You are a friendly, casual assistant.'
                  else
                    'You are an educational, patient assistant.'
                  end

    <<~INSTRUCTIONS
      #{personality}
      Session ID: #{Time.now.to_i}
      
      Guidelines:
      - Maintain consistent personality throughout the session
      - Provide helpful and accurate information
      - Adapt your tone to match the session style
    INSTRUCTIONS
  end
end

# Run examples
puts '=== Time-Aware Assistant Example ==='
time_assistant = TimeAwareAssistant.new

time_assistant.run('Please greet John appropriately for the current time') do |event|
  case event.type
  when :thought
    puts "⏰ Thinking: #{event.content}"
  when :final_answer
    puts "📝 Response: #{event.content}"
  end
end

puts "\n=== Environment-based Assistant (Beginner) Example ==="
ENV['USER_LEVEL'] = 'beginner'
ENV['DEBUG'] = 'false'

beginner_assistant = EnvironmentAwareAssistant.new

beginner_assistant.run('Calculate 15% of 200') do |event|
  case event.type
  when :thought
    puts "🎓 Thinking: #{event.content}"
  when :final_answer
    puts "📚 Response: #{event.content}"
  end
end

puts "\n=== Environment-based Assistant (Expert) Example ==="
ENV['USER_LEVEL'] = 'expert'
ENV['DEBUG'] = 'true'

expert_assistant = EnvironmentAwareAssistant.new

expert_assistant.run('Calculate 15% of 200') do |event|
  case event.type
  when :final_answer
    puts "💼 Response: #{event.content}"
  end
end

puts "\n=== Session Assistant Example ==="
session_assistant = SessionAssistant.new

session_assistant.run('Tell me about Ruby') do |event|
  case event.type
  when :thought
    puts "🔧 Thinking: #{event.content}"
  when :final_answer
    puts "🖥️ Response: #{event.content}"
  end
end

puts "\n=== Mixed: String and Method Instructions ==="
# You can still use string instructions
class StringInstructionsAgent < Soka::Agent
  provider :gemini
  model 'gemini-2.5-flash-lite'
  
  instructions 'You are a helpful assistant that always responds concisely.'
end

puts "String instructions work as before."

# And override at runtime
TimeAwareAssistant.new(
  instructions: 'Override with a custom string instruction at runtime.'
)
puts "Runtime overrides still work with both string and method-based instructions."