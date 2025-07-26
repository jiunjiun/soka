#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'
require 'soka'
require 'dotenv/load'
require 'json'

# 知識庫工具 - 儲存結構化知識
class KnowledgeBaseTool < Soka::AgentTool
  desc '管理結構化的知識庫'

  params do
    required :action, type: String, inclusion: %w[store retrieve list], desc: '操作類型'
    optional :category, type: String, desc: '知識分類'
    optional :key, type: String, desc: '知識項目的鍵值'
    optional :data, type: String, desc: '要儲存的資料（JSON 格式）'
  end

  def initialize
    super
    @knowledge_base = {}
  end

  def call(action:, category: nil, key: nil, data: nil)
    case action
    when 'store'
      store_knowledge(category, key, data)
    when 'retrieve'
      retrieve_knowledge(category, key)
    when 'list'
      list_knowledge(category)
    end
  end

  private

  def store_knowledge(category, key, data)
    return '錯誤：需要提供 category、key 和 data' unless category && key && data

    @knowledge_base[category] ||= {}
    begin
      parsed_data = JSON.parse(data)
      @knowledge_base[category][key] = parsed_data
      "已儲存知識：類別=#{category}, 鍵值=#{key}, 資料=#{parsed_data}"
    rescue JSON::ParserError
      '錯誤：資料必須是有效的 JSON 格式'
    end
  end

  def retrieve_knowledge(category, key)
    return '錯誤：需要提供 category 和 key' unless category && key

    if @knowledge_base[category] && @knowledge_base[category][key]
      "找到知識：#{@knowledge_base[category][key].to_json}"
    else
      "未找到知識：類別=#{category}, 鍵值=#{key}"
    end
  end

  def list_knowledge(category)
    category ? list_category_knowledge(category) : list_all_categories
  end

  def list_category_knowledge(category)
    return "類別 '#{category}' 不存在" unless @knowledge_base[category]

    keys = @knowledge_base[category].keys
    "類別 '#{category}' 中的知識項目：#{keys.join(', ')}"
  end

  def list_all_categories
    categories = @knowledge_base.keys
    "所有知識類別：#{categories.join(', ')}"
  end
end

# 對話分析工具 - 分析對話歷史
class ConversationAnalyzerTool < Soka::AgentTool
  desc '分析對話歷史並提取重要資訊'

  params do
    required :analysis_type, type: String,
                             inclusion: %w[summary topics sentiment count],
                             desc: '分析類型'
  end

  def call(analysis_type:, memory: nil)
    return '無法存取對話記憶' unless memory

    messages = memory.messages
    analyze_messages(analysis_type, messages)
  end

  private

  def analyze_messages(analysis_type, messages)
    case analysis_type
    when 'summary' then summarize_conversation(messages)
    when 'topics' then extract_topics(messages)
    when 'sentiment' then analyze_sentiment(messages)
    when 'count' then count_messages(messages)
    end
  end

  def summarize_conversation(messages)
    user_messages = messages.select { |m| m[:role] == 'user' }.map { |m| m[:content] }
    "對話摘要：使用者討論了 #{user_messages.size} 個主題"
  end

  def extract_topics(messages)
    # 簡單的主題提取（實際應用可以使用 NLP）
    topics = []
    messages.each do |msg|
      topics << '計算' if msg[:content].match?(/計算|數學|加|減|乘|除/)
      topics << '記憶' if msg[:content].match?(/記住|記憶|回憶/)
      topics << '個人資訊' if msg[:content].match?(/名字|年齡|歲/)
    end
    "識別到的主題：#{topics.uniq.join(', ')}"
  end

  def analyze_sentiment(messages)
    positive_count, negative_count = count_sentiments(messages)
    sentiment = determine_sentiment(positive_count, negative_count)
    "情感分析：#{sentiment}（正面詞彙：#{positive_count}，負面詞彙：#{negative_count}）"
  end

  def count_sentiments(messages)
    positive_words = %w[很好 謝謝 太棒了 高興 喜歡]
    negative_words = %w[不好 糟糕 失望 錯誤 問題]

    positive = messages.sum { |msg| positive_words.count { |word| msg[:content].include?(word) } }
    negative = messages.sum { |msg| negative_words.count { |word| msg[:content].include?(word) } }

    [positive, negative]
  end

  def determine_sentiment(positive_count, negative_count)
    if positive_count > negative_count
      '正面'
    elsif negative_count > positive_count
      '負面'
    else
      '中性'
    end
  end

  def count_messages(messages)
    user_count = messages.count { |m| m[:role] == 'user' }
    assistant_count = messages.count { |m| m[:role] == 'assistant' }
    "訊息統計：使用者 #{user_count} 則，助理 #{assistant_count} 則，總計 #{messages.size} 則"
  end
end

# 進階記憶體 Agent
class AdvancedMemoryAgent < Soka::Agent
  ai do
    provider :gemini
    model 'gemini-1.5-flash'
    temperature 0.7
  end

  tools do
    use KnowledgeBaseTool
    use ConversationAnalyzerTool
  end

  retry_on_error max_attempts: 3

  # 覆寫 run 方法以傳遞 memory 給工具
  def run(task, memory: nil)
    # 確保工具可以存取 memory
    tools.each do |tool_class|
      tool_class.new.memory = memory if tool_class.instance_methods.include?(:memory=)
    end

    super
  end
end

# 主程式
puts '=== Soka Advanced Memory Example ==='
puts "展示進階的記憶體管理功能\n\n"

agent = AdvancedMemoryAgent.new

# 初始化豐富的對話歷史
memory = Soka::Memory.new
memory.add_message('user', '我是一名軟體工程師，專長是 Ruby 和 AI')
memory.add_message('assistant', '很高興認識你！作為 Ruby 和 AI 專家，你一定對技術充滿熱情。')
memory.add_message('user', '是的，我最近在研究 LLM 應用')
memory.add_message('assistant', 'LLM 應用是個很有前景的領域！有什麼特別的專案嗎？')

# 測試 1: 儲存結構化知識
puts '測試 1: 儲存個人檔案'
result = agent.run(
  '請將這些資訊儲存到知識庫：類別="personal"，鍵值="profile"，資料={"name": "工程師", "skills": ["Ruby", "AI", "LLM"], "interest": "AI應用"}',
  memory: memory
)
puts "Agent: #{result.answer}"
puts '-' * 50

# 測試 2: 儲存專案資訊
puts "\n測試 2: 儲存專案資訊"
result = agent.run(
  '儲存專案資訊：類別="projects"，鍵值="soka"，資料={"name": "Soka Framework", "type": "AI Agent", "language": "Ruby"}',
  memory: result.memory
)
puts "Agent: #{result.answer}"
puts '-' * 50

# 測試 3: 列出知識類別
puts "\n測試 3: 查看所有知識類別"
result = agent.run(
  '請列出知識庫中的所有類別',
  memory: result.memory
)
puts "Agent: #{result.answer}"
puts '-' * 50

# 測試 4: 提取特定知識
puts "\n測試 4: 查詢個人檔案"
result = agent.run(
  '從知識庫中提取：類別="personal"，鍵值="profile"',
  memory: result.memory
)
puts "Agent: #{result.answer}"
puts '-' * 50

# 測試 5: 分析對話
puts "\n測試 5: 分析對話主題"
result = agent.run(
  '請分析我們的對話，識別主要討論的主題',
  memory: result.memory
)
puts "Agent: #{result.answer}"
puts '-' * 50

# 測試 6: 統計對話
puts "\n測試 6: 對話統計"
result = agent.run(
  '請統計我們的對話訊息數量',
  memory: result.memory
)
puts "Agent: #{result.answer}"
puts '-' * 50

# 顯示最終的記憶體狀態
puts "\n=== 最終記憶體狀態 ==="
puts "對話訊息數: #{result.memory.messages.size}"
puts '最新 3 則對話:'
result.memory.messages.last(3).each do |msg|
  puts "  [#{msg[:role]}]: #{msg[:content][0..100]}..."
end

# 顯示思考過程統計
puts "\n=== 思考過程統計 ==="
total_thoughts = 0
total_actions = 0
result.thoughts_memory.thoughts.each do |thought|
  total_thoughts += 1 if thought[:type] == 'thought'
  total_actions += 1 if thought[:type] == 'action'
end
puts "總思考次數: #{total_thoughts}"
puts "總行動次數: #{total_actions}"
