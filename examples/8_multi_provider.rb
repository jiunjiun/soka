#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'
require 'soka'
require 'dotenv/load'

# Configure Soka with all providers
Soka.setup do |config|
  # Default configuration can be overridden per agent
  config.ai do |ai|
    ai.provider = :gemini
    ai.model = 'gemini-2.5-flash-lite'
  end
end

# Simple analysis tool
class AnalysisTool < Soka::AgentTool
  desc 'Analyze text or data'

  params do
    requires :content, String, desc: 'Content to analyze'
  end

  def call(content:)
    word_count = content.split.size
    char_count = content.length
    "Analysis: #{word_count} words, #{char_count} characters"
  end
end

# Gemini Agent
class GeminiAgent < Soka::Agent
  provider :gemini
  model 'gemini-2.5-flash-lite'
  api_key ENV.fetch('GEMINI_API_KEY', nil)

  tool AnalysisTool
end

# OpenAI Agent
class OpenAIAgent < Soka::Agent
  provider :openai
  model 'gpt-4o-mini'
  api_key ENV.fetch('OPENAI_API_KEY', nil)

  tool AnalysisTool
end

# Anthropic Agent
class AnthropicAgent < Soka::Agent
  provider :anthropic
  model 'claude-3-5-haiku-latest'
  api_key ENV.fetch('ANTHROPIC_API_KEY', nil)

  tool AnalysisTool
end

# Main program
puts '=== Soka Multi-Provider Example ==='
puts "Demonstrating multiple LLM providers\n\n"

# Example 1: Different providers for same task
puts 'Example 1: Same task with different providers'
puts '-' * 50

task = 'Analyze this text: "Soka is a Ruby framework for building AI agents"'

# Try with Gemini
if ENV['GEMINI_API_KEY']
  puts "\n🔷 Using Gemini:"
  gemini_agent = GeminiAgent.new
  result = gemini_agent.run(task)
  puts "Response: #{result.final_answer}"
  puts "Provider: Gemini (#{gemini_agent.llm.model})"
else
  puts "\n🔷 Gemini: Skipped (no API key)"
end

# Try with OpenAI
if ENV['OPENAI_API_KEY']
  puts "\n🟧 Using OpenAI:"
  openai_agent = OpenAIAgent.new
  result = openai_agent.run(task)
  puts "Response: #{result.final_answer}"
  puts "Provider: OpenAI (#{openai_agent.llm.model})"
else
  puts "\n🟧 OpenAI: Skipped (no API key)"
end

# Try with Anthropic
if ENV['ANTHROPIC_API_KEY']
  puts "\n🔶 Using Anthropic:"
  anthropic_agent = AnthropicAgent.new
  result = anthropic_agent.run(task)
  puts "Response: #{result.final_answer}"
  puts "Provider: Anthropic (#{anthropic_agent.llm.model})"
else
  puts "\n🔶 Anthropic: Skipped (no API key)"
end

puts "\n=== Multi-Provider Benefits ==="
puts '1. Flexibility to choose best model for each task'
puts '2. Cost optimization (use cheaper models when appropriate)'
puts '3. Fallback options for reliability'
puts '4. Access to provider-specific features'
puts '5. Compare outputs across different models'

puts "\n=== Provider Comparison ==="
puts 'Gemini: Fast, cost-effective, good for general tasks'
puts 'OpenAI: Powerful GPT models, great for complex reasoning'
puts 'Anthropic: Claude models, excellent for analysis and writing'
