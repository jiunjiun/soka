# Soka - Ruby ReAct Agent Framework

## 專案概述

Soka 是一個基於 ReAct (Reasoning and Acting) 模式的 Ruby AI Agent 框架。它支援多種 AI 提供商（Gemini Studio、OpenAI、Anthropic），並提供物件導向的工具系統和智慧記憶體管理。

## 核心架構

### 目錄結構
```
soka/
├── lib/
│   ├── soka.rb                    # 主入口，包含 Zeitwerk 自動載入配置
│   └── soka/
│       ├── agent.rb               # Agent 基底類別，提供 DSL 和執行邏輯
│       ├── agent_tool.rb          # 工具基底類別，包含參數驗證系統
│       ├── agent_tools/
│       │   └── params_validator.rb # 參數驗證模組
│       ├── agents/                # Agent 功能模組
│       │   ├── cache_handler.rb   # 快取處理
│       │   ├── dsl_methods.rb     # DSL 方法定義
│       │   ├── hook_manager.rb    # 生命週期鉤子管理
│       │   ├── llm_builder.rb     # LLM 實例建構
│       │   ├── retry_handler.rb   # 重試機制
│       │   └── tool_builder.rb    # 工具建構與管理
│       ├── configuration.rb       # 全域配置系統
│       ├── llm.rb                 # LLM 統一介面層
│       ├── llms/                  # LLM 提供商實作
│       │   ├── base.rb           # LLM 基底類別
│       │   ├── concerns/         # 共用功能模組
│       │   │   ├── response_parser.rb    # 回應解析
│       │   │   └── streaming_handler.rb  # 串流處理
│       │   ├── gemini.rb         # Google Gemini 實作
│       │   ├── openai.rb         # OpenAI 實作
│       │   └── anthropic.rb      # Anthropic 實作
│       ├── engines/              # 推理引擎
│       │   ├── base.rb          # 引擎基底類別
│       │   ├── concerns/        # 引擎共用模組
│       │   │   ├── prompt_template.rb     # 提示詞模板
│       │   │   └── response_processor.rb  # 回應處理
│       │   ├── react.rb         # ReAct 推理引擎
│       │   └── reasoning_context.rb # 推理上下文管理
│       ├── memory.rb             # 對話記憶體管理
│       ├── thoughts_memory.rb    # 思考過程記憶體
│       ├── result.rb             # 結果物件封裝
│       ├── test_helpers.rb       # RSpec 測試輔助
│       └── version.rb            # 版本定義
├── examples/
│   ├── basic_example.rb          # 基礎使用範例
│   ├── advanced_memory_example.rb # 進階記憶體範例
│   └── memory_example.rb         # 記憶體使用範例
├── spec/                         # RSpec 測試
└── test_soka.rb                 # 快速測試腳本
```

## 核心元件說明

### 1. Agent 系統 (`agent.rb`)
- 提供 DSL 來定義 AI 設定、工具註冊、重試機制
- 支援條件式工具載入 (`if:` 選項)
- 內建生命週期鉤子 (before_action, after_action, on_error)
- 使用 `times` 迴圈取代 `loop` 來控制迭代次數
- 模組化設計：將功能分離成多個 concern 模組
  - `CacheHandler`: 快取機制
  - `DSLMethods`: DSL 方法定義
  - `HookManager`: 生命週期鉤子管理
  - `LLMBuilder`: LLM 實例建構
  - `RetryHandler`: 重試處理
  - `ToolBuilder`: 工具建構與管理

### 2. 工具系統 (`agent_tool.rb`)
- 類似 Grape API 的參數定義系統
- 內建參數驗證（presence, length, inclusion, format）
- 支援必要和可選參數
- 自動生成工具描述 schema

### 3. ReAct 引擎 (`engines/react.rb`)
- 實作標籤化的 ReAct 流程：`<Thought>`, `<Action>`, `<Observation>`, `<Final_Answer>`
- 使用 Struct 取代 OpenStruct（符合 Rubocop 規範）
- 自動管理對話上下文和工具執行
- 計算信心分數（基於迭代次數）
- 使用 `ReasoningContext` 管理推理狀態
- 共用模組：
  - `PromptTemplate`: 提示詞模板管理
  - `ResponseProcessor`: 回應處理邏輯

### 4. LLM 整合
- **LLM 統一介面層 (`llm.rb`)**
  - 提供統一的 API 介面
  - 支援串流和非串流模式
  - 自動路由到對應的提供商實作
- **LLM 提供商實作 (`llms/`)**
  - Gemini: 使用 Google Generative AI API，預設使用 `gemini-2.5-flash-lite`
  - OpenAI: 支援 GPT-4 系列，包含串流功能
  - Anthropic: 支援 Claude 3 系列，處理系統提示詞
  - 共用模組：
    - `ResponseParser`: 統一的回應解析
    - `StreamingHandler`: 串流回應處理
- 內建錯誤處理和重試機制

### 5. 記憶體系統
- `Memory`: 管理對話歷史
- `ThoughtsMemory`: 記錄完整的 ReAct 思考過程
- 支援初始記憶體載入

## 設計決策

### 1. 使用 Zeitwerk 自動載入
- 簡化 require 管理
- 支援熱重載（開發環境）
- 自動處理命名空間

### 2. Dry-rb 生態系整合
- `dry-validation`: 強大的參數驗證
- `dry-struct`: 類型安全的資料結構
- `dry-types`: 類型定義和轉換

### 3. 配置系統設計
- 支援全域配置和實例級別覆寫
- 區塊式 DSL 提供直覺的配置方式
- Fallback 機制確保服務可用性
- 配置項目包含 AI 提供商和效能設定

### 4. 錯誤處理策略
- 分層的錯誤類別繼承
- 工具執行錯誤不會中斷整個流程
- 可配置的重試機制（指數退避）

## 測試策略

### 單元測試
- 使用 RSpec 3
- 提供 `TestHelpers` 模組來 mock AI 回應
- 支援工具 mock 和錯誤模擬

### 整合測試
- `test_soka.rb`: 不需要真實 API key 的快速測試
- `examples/basic_example.rb`: 實際 API 整合測試

## 開發指南

### 新增 AI 提供商
1. 在 `lib/soka/llms/` 建立新檔案
2. 繼承 `Soka::LLMs::Base`
3. 實作必要方法：
   - `default_model`
   - `base_url`
   - `chat(messages, **params)`
   - `parse_response(response)`
4. 在 `LLM#create_provider` 方法中加入新提供商

### 新增工具
1. 繼承 `Soka::AgentTool`
2. 使用 `desc` 定義描述
3. 使用 `params` 區塊定義參數
4. 實作 `call` 方法

### 自訂引擎
1. 繼承 `Soka::Engines::Base`
2. 實作 `reason(task, &block)` 方法
3. 使用 `emit_event` 發送事件
4. 回傳繼承自 Struct 的結果物件
5. 可以使用 concerns 模組來共享功能

## Rubocop 相容性
- 符合 Ruby 3.0+ 標準
- 已修正主要問題：
  - 使用 `Struct` 取代 `OpenStruct`
  - 使用 `format` 取代 `String#%`
  - 使用 `times` 取代 `loop`
  - 移除未使用的 MODELS 常數

## 效能考量
- 最大迭代次數限制（預設 10）
- 請求超時設定（預設 30 秒）
- 記憶體使用優化（按需載入）
- 支援工具並行執行（實驗性）

## 安全性
- API key 透過環境變數管理
- 輸入參數驗證
- 錯誤訊息不洩露敏感資訊
- 支援 `.env` 檔案（不納入版控）
- 統一的錯誤處理層次

## 未來擴展
- [ ] 支援更多 LLM 提供商（Cohere、Hugging Face）
- [x] 實作快取機制（已在 `CacheHandler` 中實作）
- [ ] 支援向量資料庫整合
- [ ] 增加更多內建工具
- [ ] WebSocket 支援實時對話
- [ ] 支援函數式工具（直接使用方法作為工具）
- [ ] 支援並行工具執行（實驗性功能）

## 開發規範

### 程式碼品質檢查
- **當調整程式碼時，最後一步請執行 Rubocop 來檢查程式碼是否符合規則**
- **當 Rubocop 有任何問題時，請修正直到符合所有規則為止**
- **當有調整程式碼的時候，最後一步請幫我執行 code review，避免有冗餘的設計，以及程式碼的簡潔性**
  - 檢查是否有不必要的中間層或方法
  - 確認參數傳遞是否直接且清晰
  - 移除重複的程式碼
  - 避免過度抽象化

### 程式碼文檔
- **當有調整程式碼的時候，對程式碼的 method 加上註解以及說明**
  - 使用 YARD 格式的註解
  - 包含方法的用途說明
  - 說明參數的類型和用途
  - 說明回傳值的類型和意義
  - 對於複雜的邏輯，加上實作細節的說明
