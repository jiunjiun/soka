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
  tool TimeTool
end

# 初始化記憶體
memory_array = [
  { role: 'user', content: '我叫小華，今年 35 歲' },
  { role: 'assistant', content: '很高興認識你，小華！我會記住你是 35 歲的。' }
]
memory = Soka::Memory.new(memory_array)

agent = DemoAgent.new(memory:)
result = agent.run('請問現在是幾點？')
puts result.final_answer
result = agent.run('我叫什麼名字？幾歲?')
puts result.final_answer
