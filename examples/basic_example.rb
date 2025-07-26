#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'
require 'soka'
require 'dotenv/load'

# 設定 Soka
Soka.setup do |config|
  config.ai do |ai|
    ai.provider = :gemini
    ai.model = 'gemini-2.5-flash-lite'
    ai.api_key = ENV.fetch('GEMINI_API_KEY', nil)
  end

  config.performance do |perf|
    perf.max_iterations = 5
    perf.timeout = 30
  end
end

# 定義一個簡單的搜尋工具
class SearchTool < Soka::AgentTool
  desc 'Search the web for information'

  params do
    requires :query, String, desc: 'The query to search for'
  end

  def call(query:)
    puts "SearchTool call: #{query}"
    # 這是一個模擬的搜尋結果
    case query.downcase
    when /weather|天氣/
      '今天台北晴天，溫度 28°C，濕度 65%'
    when /news|新聞/
      '今日頭條：AI 技術突破新里程碑'
    else
      "搜尋 '#{query}' 的相關資訊..."
    end
  end
end

# 定義時間工具
class TimeTool < Soka::AgentTool
  desc 'Get current time and date'

  def call
    puts 'TimeTool call'
    Time.now.strftime('%Y年%m月%d日 %H:%M:%S')
  end
end

# 定義 Agent
class DemoAgent < Soka::Agent
  tool SearchTool
  tool TimeTool
end

# 使用 Agent
agent = DemoAgent.new

puts '=== Soka Demo Agent ==='
puts

# 示例 1: 詢問天氣
puts '問題: 今天台北的天氣如何？'
puts '-' * 50

agent.run('今天台北的天氣如何？') do |event|
  case event.type
  when :thought
    puts "💭 思考: #{event.content}"
  when :action
    puts "🔧 行動: 使用工具 #{event.content[:tool]}"
  when :observation
    puts "👀 觀察: #{event.content}"
  when :final_answer
    puts "✅ 答案: #{event.content}"
  end
end

puts
puts '=' * 50
puts

# 示例 2: 詢問時間
puts '問題: 現在幾點了？'
puts '-' * 50

result = agent.run('現在幾點了？')
puts "✅ 答案: #{result.final_answer}"
puts "📊 信心度: #{(result.confidence_score * 100).round(1)}%"
puts "⏱️  迭代次數: #{result.iterations}"
