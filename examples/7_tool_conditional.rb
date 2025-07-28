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

# Development-only debugging tool
class DebugTool < Soka::AgentTool
  desc 'Debug internal state (dev only)'

  def call
    "Debug info: Memory size=#{@agent&.memory&.messages&.size || 0}, Time=#{Time.now}"
  end
end

# Production monitoring tool
class MonitoringTool < Soka::AgentTool
  desc 'Monitor system metrics'

  def call
    "System metrics: CPU=#{rand(10..90)}%, Memory=#{rand(30..70)}%, Uptime=#{rand(1..100)}h"
  end
end

# Admin-only tool
class AdminTool < Soka::AgentTool
  desc 'Perform admin operations'

  params do
    requires :operation, String, desc: 'Admin operation to perform'
  end

  def call(operation:)
    "Admin operation '#{operation}' completed successfully"
  end
end

# Feature flag tool
class FeatureFlagTool < Soka::AgentTool
  desc 'Check feature flags'

  params do
    requires :flag, String, desc: 'Feature flag name'
  end

  def call(flag:)
    # Simulate feature flag service
    enabled = %w[new_ui dark_mode beta_features].include?(flag)
    "Feature '#{flag}' is #{enabled ? 'enabled' : 'disabled'}"
  end
end

# Environment-aware agent
class ConditionalAgent < Soka::Agent
  # Always available tools
  tool FeatureFlagTool

  # Conditional tools based on environment
  tool DebugTool, if: -> { ENV['ENVIRONMENT'] == 'development' }
  tool MonitoringTool, if: -> { %w[staging production].include?(ENV['ENVIRONMENT']) }
  tool AdminTool, if: -> { ENV['USER_ROLE'] == 'admin' }
end

# Dynamic condition agent
class DynamicConditionAgent < Soka::Agent
  # Load tool based on time of day
  tool DebugTool, if: -> { Time.now.hour.between?(9, 17) } # Business hours only
  
  # Load based on environment variable
  tool MonitoringTool, if: -> { ENV['ENABLE_MONITORING'] == 'true' }
  
  # Multiple conditions
  tool AdminTool, if: -> { ENV['USER_ROLE'] == 'admin' && ENV['SECURE_MODE'] == 'true' }
end

# Main program
puts '=== Soka Conditional Tool Example ==='
puts "Demonstrating conditional tool loading\n\n"

# Example 1: Environment-based tools
puts 'Example 1: Environment-based tool loading'
puts '-' * 50

environments = %w[development staging production]

environments.each do |env|
  ENV['ENVIRONMENT'] = env
  agent = ConditionalAgent.new
  
  puts "\nEnvironment: #{env}"
  puts "Loaded tools: #{agent.tools.map { |t| t.class.name }.join(', ')}"
  
  # Try to use monitoring
  result = agent.run('Check system monitoring metrics')
  puts "Result: #{result.final_answer}"
end

puts "\n" + '=' * 50 + "\n"

# Example 2: Role-based tools
puts 'Example 2: Role-based tool access'
puts '-' * 50

roles = %w[user admin guest]

roles.each do |role|
  ENV['USER_ROLE'] = role
  ENV['ENVIRONMENT'] = 'production'
  agent = ConditionalAgent.new
  
  puts "\nUser role: #{role}"
  puts "Available tools: #{agent.tools.map { |t| t.class.name }.join(', ')}"
  
  if role == 'admin'
    result = agent.run('Perform admin operation: restart_service')
    puts "Admin result: #{result.final_answer}"
  else
    puts "Admin tools not available for #{role} role"
  end
end

puts "\n" + '=' * 50 + "\n"

# Example 3: Dynamic conditions
puts 'Example 3: Dynamic condition checking'
puts '-' * 50

# Set up dynamic conditions
ENV['ENABLE_MONITORING'] = 'true'
ENV['USER_ROLE'] = 'admin'
ENV['SECURE_MODE'] = 'true'

dynamic_agent = DynamicConditionAgent.new
puts "Current time: #{Time.now}"
puts "Business hours tool available: #{Time.now.hour.between?(9, 17)}"
puts "Monitoring enabled: #{ENV['ENABLE_MONITORING']}"
puts "Admin with secure mode: #{ENV['USER_ROLE'] == 'admin' && ENV['SECURE_MODE'] == 'true'}"
puts "\nLoaded tools: #{dynamic_agent.tools.map { |t| t.class.name }.join(', ')}"

result = dynamic_agent.run('List all available debugging options')
puts "\nResult: #{result.final_answer}"

puts "\n" + '=' * 50 + "\n"

# Example 4: Feature flags
puts 'Example 4: Feature flag integration'
puts '-' * 50

agent = ConditionalAgent.new
features = %w[new_ui dark_mode legacy_support beta_features]

puts "Checking feature flags:"
features.each do |feature|
  result = agent.run("Check if feature flag '#{feature}' is enabled")
  puts "- #{feature}: #{result.final_answer.include?('enabled') ? '✓' : '✗'}"
end

puts "\n=== Conditional Tool Benefits ==="
puts "1. Environment-specific functionality"
puts "2. Role-based access control"
puts "3. Feature flag integration"
puts "4. Resource optimization"
puts "5. Security through tool isolation"

puts "\n=== Use Cases ==="
puts "1. Debug tools only in development"
puts "2. Admin tools for privileged users"
puts "3. Monitoring in production only"
puts "4. Beta features behind flags"
puts "5. Time-based tool availability"