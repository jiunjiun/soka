#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'
require 'soka'
require 'dotenv/load'
require 'singleton'

# 設定 Soka
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

# 計算工具 - 簡單的數學計算
class CalculatorTool < Soka::AgentTool
  desc '執行基本數學運算'

  params do
    requires :expression, String, desc: "數學表達式，例如: '2 + 2' 或 '10 * 5'"
  end

  def call(expression:)
    # 簡單的數學表達式評估（生產環境應使用更安全的方法）
    result = eval(expression) # rubocop:disable Security/Eval
    "計算結果: #{expression} = #{result}"
  rescue StandardError => e
    "計算錯誤: #{e.message}"
  end
end

# 共享記憶體管理器
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

# 記憶工具 - 儲存和提取資訊
class MemoryTool < Soka::AgentTool
  desc '記住重要資訊'

  params do
    requires :key, String, desc: '資訊的鍵值'
    requires :value, String, desc: '要記住的內容'
  end

  def call(key:, value:)
    SharedMemory.instance.store(key, value)
    "已記住: #{key} = #{value}"
  end
end

# 回憶工具 - 提取之前記住的資訊
class RecallTool < Soka::AgentTool
  desc '回憶之前記住的資訊'

  params do
    requires :key, String, desc: '要回憶的資訊鍵值'
  end

  def call(key:)
    if SharedMemory.instance.exists?(key)
      value = SharedMemory.instance.retrieve(key)
      "回憶到: #{key} = #{value}"
    else
      "沒有找到關於 '#{key}' 的記憶"
    end
  end
end

# 定義 Agent
class MemoryAgent < Soka::Agent
  tool CalculatorTool
  tool MemoryTool
  tool RecallTool
end

# 主程式
puts '=== Soka Memory Example ==='
puts "測試 Agent 的記憶體功能\n\n"

# 主程式開始

# 初始化記憶體 - 預先載入一些資訊
initial_memory = Soka::Memory.new
initial_memory.add(role: 'user', content: '我叫小明，今年 25 歲')
initial_memory.add(role: 'assistant', content: '很高興認識你，小明！我會記住你是 25 歲的。')

# 測試案例 1: 基本計算和記憶
puts '測試 1: 基本計算和記憶'
# 使用初始記憶體的 agent
agent_with_memory = MemoryAgent.new(memory: initial_memory)
result = agent_with_memory.run(
  "請計算 15 * 8 的結果，並且記住這個計算結果，鍵值使用 'first_calc'"
)
puts "Agent: #{result.final_answer}"
puts "信心度: #{(result.confidence_score * 100).round(1)}%"
puts "疊代次數: #{result.iterations}"
puts '-' * 50

# 測試案例 2: 回憶之前的資訊
puts "\n測試 2: 回憶之前的計算"
# 繼續使用同一個 agent，因為它已經有了記憶體
result = agent_with_memory.run(
  "請回憶一下 'first_calc' 的值是多少？"
)
puts "Agent: #{result.final_answer}"
puts '-' * 50

# 測試案例 3: 使用記憶中的資訊進行新計算
puts "\n測試 3: 複雜的記憶操作"
result = agent_with_memory.run(
  "請記住 pi 的值是 3.14159，然後計算半徑為 5 的圓面積（使用 pi * r * r），並把結果記為 'circle_area'"
)
puts "Agent: #{result.final_answer}"
puts '-' * 50

# 測試案例 4: 回憶初始記憶體中的資訊
puts "\n測試 4: 回憶初始資訊"
result = agent_with_memory.run(
  '你還記得我的名字和年齡嗎？'
)
puts "Agent: #{result.final_answer}"
puts '-' * 50

# 顯示完整的對話歷史
puts "\n=== 完整對話歷史 ==="
agent_with_memory.memory.messages.each_with_index do |msg, idx|
  puts "#{idx + 1}. [#{msg[:role]}]: #{msg[:content][0..100]}#{'…' if msg[:content].length > 100}"
end

# 顯示最後一次的思考過程
puts "\n=== 最後一次的思考過程 ==="
if result.thoughts&.any?
  result.thoughts.each_with_index do |thought_item, idx|
    step = thought_item[:step] || (idx + 1)
    content = thought_item[:thought] || thought_item[:content] || ''
    puts "#{step}. #{content[0..200]}#{'…' if content.length > 200}"
  end
else
  puts '沒有思考過程記錄'
end
