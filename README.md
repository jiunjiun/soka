# Soka

<p align="center">
  <strong>基於 ReAct 模式的 Ruby AI Agent 框架</strong>
</p>

<p align="center">
  <a href="#特性">特性</a> •
  <a href="#安裝">安裝</a> •
  <a href="#快速開始">快速開始</a> •
  <a href="#進階功能">進階功能</a> •
  <a href="#api-文件">API 文件</a> •
  <a href="#貢獻">貢獻</a>
</p>

Soka 是一個基於 ReAct (Reasoning and Acting) 模式的 Ruby AI Agent 框架，支援多種 AI 提供商，提供物件導向的工具系統和智慧記憶體管理。它讓你能夠快速建立智能代理，處理複雜的推理和行動任務。

## 特性

- 🤖 **多 AI 提供商支援**: Google Gemini、OpenAI、Anthropic
- 🛠️ **物件導向工具系統**: 類似 Grape API 的參數定義和驗證
- 🧠 **智慧記憶體管理**: 對話歷史和思考過程記錄
- 🔄 **ReAct 推理模式**: 標籤化的思考-行動-觀察循環
- ⚡ **靈活配置系統**: 全域和實例級別的配置選項
- 🔁 **錯誤處理和重試**: 內建指數退避重試機制
- 🧪 **測試友好**: 完整的測試輔助工具
- 📝 **完整類型支援**: 使用 dry-rb 生態系統
- 🚀 **模組化設計**: 易於擴展和維護
- 💾 **內建快取機制**: 提升效能和節省成本

## 安裝

將以下內容加入你的 Gemfile：

```ruby
gem 'soka'
```

然後執行：

```bash
bundle install
```

或者直接安裝：

```bash
gem install soka
```

## 快速開始

### 1. 設定 API Key

```bash
# 方法 1: 環境變數
export GEMINI_API_KEY="your-api-key"

# 方法 2: 建立 .env 檔案
echo "GEMINI_API_KEY=your-api-key" > .env
```

取得 API Key:
- [Google AI Studio](https://makersuite.google.com/app/apikey) (Gemini)
- [OpenAI Platform](https://platform.openai.com/api-keys)
- [Anthropic Console](https://console.anthropic.com/)

### 2. 基本使用

```ruby
require 'soka'

# 建立簡單的時間工具
class TimeTool < Soka::AgentTool
  desc "Get current time"
  
  def call
    Time.now.strftime('%Y-%m-%d %H:%M:%S')
  end
end

# 建立 Agent
class SimpleAgent < Soka::Agent
  tool TimeTool
end

# 執行
agent = SimpleAgent.new
result = agent.run("現在幾點？")
puts result.final_answer
```

### 3. 執行範例

```bash
# 測試基本功能（不需要 API key）
ruby test_soka.rb

# 執行完整範例（需要 API key）
ruby examples/basic_example.rb
```

## 核心概念

### 全域配置

```ruby
Soka.setup do |config|
  # AI 配置
  config.ai do |ai|
    ai.provider = :gemini  # :gemini, :openai, :anthropic
    ai.model = 'gemini-2.5-flash-lite'
    ai.api_key = ENV['GEMINI_API_KEY']
    
    # Fallback 機制：當主要提供商失敗時自動切換
    ai.fallback_provider = :openai
    ai.fallback_model = 'gpt-4-turbo'
    ai.fallback_api_key = ENV['OPENAI_API_KEY']
  end
  
  # 效能配置
  config.performance do |perf|
    perf.max_iterations = 10      # ReAct 最大迭代次數
    perf.timeout = 30             # API 調用超時（秒）
    perf.parallel_tools = false   # 實驗性功能
  end
  
  # 預設工具
  config.tools = [SearchTool, TimeTool]
end
```

### 定義工具

工具是 Agent 可以使用的功能模組：

```ruby
class SearchTool < Soka::AgentTool
  desc "Search the web for information"
  
  params do
    requires :query, String, desc: "The query to search for"
    optional :location, String, desc: "Location context", default: "Taiwan"
    
    # 參數驗證
    validates :query, presence: true, length: { minimum: 1, maximum: 500 }
    validates :location, inclusion: { in: %w[Taiwan Japan Korea US] }, allow_nil: true
  end
  
  def call(query:, location: "Taiwan")
    # 實際搜尋邏輯
    perform_search(query, location)
  rescue => e
    { error: e.message, tool: self.class.name }
  end
  
  private
  
  def perform_search(query, location)
    # 這裡可以調用真實的搜尋 API
    "搜尋 #{query} 在 #{location} 的結果..."
  end
end
```

### 定義 Agent

Agent 是執行 ReAct 推理的主體：

```ruby
class WeatherAgent < Soka::Agent
  # AI 設定（覆寫全域設定）
  provider :gemini
  model 'gemini-2.5-flash-lite'
  max_iterations 10
  timeout 30
  
  # 註冊工具
  tool SearchTool
  tool TimeTool
  
  # 條件式工具註冊
  tool CalculatorTool, if: -> { ENV['ENABLE_CALCULATOR'] == 'true' }
  
  # 批量註冊
  tools SearchTool, TimeTool, WeatherTool
  
  # 自定義工具（函數式）
  tool :get_weather, "Get weather for a location"
  
  # 重試配置
  retry_config do
    max_retries 3
    backoff_strategy :exponential  # :exponential, :linear, :constant
    retry_on [Timeout::Error, Net::ReadTimeout]
  end
  
  # 生命週期鉤子
  before_action :track_action
  after_action :update_metrics
  on_error :handle_error
  
  private
  
  def get_weather(location:)
    "#{location} 目前是晴天，溫度 25°C"
  end
  
  def track_action(action)
    # 追蹤動作執行
    @action_count ||= 0
    @action_count += 1
  end
  
  def update_metrics(result)
    # 更新統計指標
    # metrics.record(result)
  end
  
  def handle_error(error, context)
    # 處理錯誤
    :continue  # 或 :stop 來中斷執行
  end
end
```

### 使用 Agent

#### 區塊模式（即時回饋）

適合需要顯示執行過程的場景：

```ruby
agent = WeatherAgent.new

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
  when :error
    puts "❌ 錯誤: #{event.content}"
  end
end
```

#### 直接模式（取得結果）

適合只需要最終結果的場景：

```ruby
agent = WeatherAgent.new
result = agent.run('今天台北的天氣如何？')

# 結果物件提供豐富的資訊
puts result.final_answer      # 最終答案
puts result.confidence_score  # 信心分數 (0.0-1.0)
puts result.iterations       # 使用的迭代次數
puts result.status          # :success, :failed, :timeout, :max_iterations_reached
puts result.execution_time  # 執行時間（如果有記錄）

# 檢查執行狀態
if result.successful?
  puts "成功：#{result.final_answer}"
elsif result.failed?
  puts "失敗：#{result.error}"
elsif result.timeout?
  puts "執行超時"
elsif result.max_iterations_reached?
  puts "達到最大迭代次數"
end
```

### 記憶體管理

#### 基本對話記憶體

```ruby
# 初始化帶有歷史的 Agent
memory = [
  { role: 'user', content: '我叫小明' },
  { role: 'assistant', content: '你好，小明！很高興認識你。' }
]

agent = WeatherAgent.new(memory: memory)
result = agent.run('我的名字是什麼？')
# => "你的名字是小明。"

# 記憶體會自動更新
puts agent.memory
# <Soka::Memory> [
#   { role: 'user', content: '我叫小明' },
#   { role: 'assistant', content: '你好，小明！很高興認識你。' },
#   { role: 'user', content: '我的名字是什麼？' },
#   { role: 'assistant', content: '你的名字是小明。' }
# ]
```

#### 思考過程記憶體

```ruby
# 查看完整的思考過程
puts agent.thoughts_memory
# <Soka::ThoughtsMemory> (3 sessions, 2 successful, 1 failed, avg confidence: 0.82, avg iterations: 2.3)

# 取得特定 session 的詳細資訊
last_session = agent.thoughts_memory.last_session
puts last_session[:thoughts]  # 所有思考步驟
puts last_session[:confidence_score]  # 該次執行的信心分數
```

## 進階功能

### ReAct 流程格式

Soka 使用標籤化的 ReAct 格式：

```xml
<Thought>我需要搜尋台北的天氣資訊</Thought>
<Action>
Tool: search
Parameters: {"query": "台北天氣", "location": "Taiwan"}
</Action>
<Observation>台北今天晴天，溫度 28°C，濕度 65%</Observation>
<Thought>我已經獲得天氣資訊，可以回答使用者了</Thought>
<Final_Answer>今天台北的天氣是晴天，溫度為 28°C，濕度為 65%。</Final_Answer>
```

### 結果物件結構

```ruby
# Result 物件屬性
result.input            # 使用者輸入
result.thoughts         # 思考步驟陣列
result.final_answer     # 最終答案
result.confidence_score # 信心分數 (0.0-1.0)
result.status          # 狀態 (:success, :failed, :timeout, :max_iterations_reached)
result.error           # 錯誤訊息（如果有）
result.execution_time  # 執行時間（秒）
result.iterations      # 迭代次數

# 完整結構
{
  input: "使用者輸入",
  thoughts: [
    {
      step: 1,
      thought: "思考內容",
      action: { tool: "search", params: { query: "..." } },
      observation: "觀察結果"
    }
  ],
  final_answer: "最終答案",
  confidence_score: 0.85,  # 基於迭代次數計算
  status: :success,        # :success, :failed, :timeout, :max_iterations_reached
  error: nil,             # 錯誤訊息（如果有）
  execution_time: 1.23,   # 執行時間（秒）
  iterations: 2,          # 迭代次數
  created_at: Time        # 建立時間
}
```

### 測試支援

Soka 提供完整的測試輔助工具：

```ruby
RSpec.describe WeatherAgent do
  include Soka::TestHelpers
  
  it "answers weather questions" do
    # Mock AI 回應
    mock_ai_response({
      thoughts: [
        {
          step: 1,
          thought: "需要搜尋天氣資訊",
          action: { tool: "search", params: { query: "台北天氣" } },
          observation: "台北今天晴天"
        }
      ],
      final_answer: "台北今天是晴天。"
    })
    
    # Mock 工具回應
    mock_tool_response(SearchTool, "台北今天晴天")
    
    agent = described_class.new
    result = agent.run("台北天氣如何？")
    
    expect(result).to be_successful
    expect(result.final_answer).to include("晴天")
    expect(result).to have_thoughts_count(1)
    expect(result).to have_confidence_score_above(0.8)
  end
  
  it "handles tool errors gracefully" do
    allow_tool_to_fail(SearchTool, StandardError.new("API 錯誤"))
    
    agent = described_class.new
    result = agent.run("搜尋測試")
    
    expect(result).to be_failed
    expect(result.error).to include("API 錯誤")
  end
end
```

### 自訂引擎

你可以實作自己的推理引擎：

```ruby
class CustomEngine < Soka::Engines::Base
  def reason(task, &block)
    # 實作自定義推理邏輯
    context = Soka::Engines::ReasoningContext.new(
      task: task,
      event_handler: block,
      max_iterations: max_iterations
    )
    
    # 使用 emit_event 發送事件
    emit_event(:thought, "開始推理...", &block)
    
    # 執行推理...
    
    # 回傳結果（使用 Struct）
    Soka::Engines::React::ReasonResult.new(
      input: task,
      thoughts: thoughts,
      final_answer: answer,
      status: :success,
      confidence_score: calculate_confidence_score(thoughts, :success)
    )
  end
end

# 使用自訂引擎
agent = MyAgent.new(engine: CustomEngine)
```

## API 文件

### 支援的 AI 提供商

#### Google Gemini
- 模型：`gemini-2.5-flash`, `gemini-2.5-flash-lite`, `gemini-pro`
- 環境變數：`GEMINI_API_KEY`
- 特點：快速回應，成本效益高
- 預設模型：`gemini-2.5-flash-lite`

#### OpenAI
- 模型：`gpt-4`, `gpt-4-turbo`, `gpt-3.5-turbo`
- 環境變數：`OPENAI_API_KEY`
- 特點：支援串流回應，強大的推理能力

#### Anthropic
- 模型：`claude-3-opus`, `claude-3-sonnet`, `claude-3-haiku`
- 環境變數：`ANTHROPIC_API_KEY`
- 特點：長上下文支援，優秀的程式碼理解

### 配置選項

| 選項 | 類型 | 預設值 | 說明 |
|------|------|--------|------|
| `ai.provider` | Symbol | `:gemini` | AI 提供商 |
| `ai.model` | String | `"gemini-2.5-flash-lite"` | 使用的模型 |
| `ai.api_key` | String | nil | API 金鑰 |
| `ai.fallback_provider` | Symbol | nil | 備用提供商 |
| `performance.max_iterations` | Integer | 10 | 最大迭代次數 |
| `performance.timeout` | Integer | 30 | 超時時間（秒） |
| `performance.parallel_tools` | Boolean | false | 並行工具執行 |

### 工具參數驗證

| 驗證器 | 選項 | 說明 |
|--------|------|------|
| `presence` | `true/false` | 值不能為空 |
| `length` | `minimum`, `maximum` | 字串長度限制 |
| `inclusion` | `in`, `allow_nil` | 值必須在指定列表中 |
| `format` | `with` | 符合正則表達式 |

## 效能最佳化

1. **使用適當的模型**：
   - 簡單任務使用 `gemini-2.5-flash-lite` 或 `gpt-3.5-turbo`
   - 複雜推理使用 `claude-4-sonnet` 或 `gpt-4`

2. **控制迭代次數**：
   ```ruby
   agent = MyAgent.new(max_iterations: 5)  # 限制迭代次數
   ```

3. **使用快取機制**：
   ```ruby
   agent = MyAgent.new(cache: true, cache_ttl: 300)  # 5 分鐘快取
   ```

4. **工具並行執行**（實驗性）：
   ```ruby
   config.performance.parallel_tools = true
   ```

## 故障排除

### 常見問題

1. **API Key 錯誤**
   ```
   Soka::LLMError: API key is required
   ```
   解決：確保已設定正確的環境變數或在配置中提供 API key

2. **超時錯誤**
   ```
   Soka::LLMError: Request timed out
   ```
   解決：增加超時時間或使用更快的模型

3. **達到最大迭代次數**
   ```
   Status: max_iterations_reached
   ```
   解決：簡化問題或增加 `max_iterations`

### 除錯技巧

```ruby
# 調整最大迭代次數
Soka.configure do |c|
  c.performance.max_iterations = 20
end

# 使用區塊模式查看執行過程
agent.run(query) do |event|
  p event  # 印出所有事件
end

# 檢查思考過程
result = agent.run(query)
result.thoughts.each do |thought|
  puts "Step #{thought[:step]}: #{thought[:thought]}"
  puts "Action: #{thought[:action]}" if thought[:action]
  puts "Observation: #{thought[:observation]}" if thought[:observation]
end
```

## 開發

```bash
# 安裝依賴
bundle install

# 執行測試
bundle exec rspec

# 執行 Rubocop
bundle exec rubocop

# 開啟互動式 console
bin/console

# 建立新版本
# 1. 更新 lib/soka/version.rb
# 2. 更新 CHANGELOG.md
# 3. 提交變更
# 4. 建立標籤
bundle exec rake release
```

## 貢獻

我們歡迎各種形式的貢獻！

1. Fork 專案
2. 建立功能分支 (`git checkout -b feature/amazing-feature`)
3. 提交變更 (`git commit -m 'Add some amazing feature'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 開啟 Pull Request

請確保：
- 添加適當的測試
- 更新相關文件
- 遵循現有的程式碼風格
- 通過 Rubocop 檢查

## 授權

本專案採用 MIT 授權條款。詳見 [LICENSE](LICENSE) 檔案。

## 致謝

- 感謝 [ReAct 論文](https://arxiv.org/abs/2210.03629) 提供的理論基礎
- 感謝 [Regent](https://github.com/alextwoods/regent) 專案的架構啟發
- 感謝所有貢獻者的付出

---

<p align="center">
  用 ❤️ 在台灣製造
</p>