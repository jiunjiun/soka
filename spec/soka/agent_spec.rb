# frozen_string_literal: true

RSpec.describe Soka::Agent do
  # Helper method to mock LLM responses
  def mock_llm_response(agent,
                        content = '<Thought>Processing</Thought><FinalAnswer>The weather is sunny.</FinalAnswer>')
    allow(agent.llm).to receive(:chat).and_return(
      Soka::LLMs::Result.new(content: content)
    )
  end

  def mock_llm_error(agent, error_message = 'LLM request failed')
    allow(agent.llm).to receive(:chat).and_raise(Soka::LLMError, error_message)
  end

  let(:test_agent_class) do
    test_tool_class = Class.new(Soka::AgentTool) do
      def self.tool_name
        'test_tool'
      end

      desc 'A test tool'

      params do
        requires :query, String, desc: 'Test query'
      end

      def call(query:)
        "Test response for: #{query}"
      end
    end

    stub_const('TestTool', test_tool_class)

    Class.new(described_class) do
      provider :gemini
      model 'test-model'
      api_key 'test-key'

      tool TestTool
    end
  end

  describe '.provider, .model, .api_key' do
    it 'configures AI settings' do
      agent_class = create_agent_with_ai_config
      expect_ai_configuration(agent_class)
    end

    def create_agent_with_ai_config
      Class.new(described_class) do
        provider :openai
        model 'gpt-4'
        api_key 'test-key'
      end
    end

    def expect_ai_configuration(agent_class)
      aggregate_failures do
        expect(agent_class._provider).to eq(:openai)
        expect(agent_class._model).to eq('gpt-4')
        expect(agent_class._api_key).to eq('test-key')
      end
    end
  end

  describe '.tool' do
    it 'registers inline tools' do
      agent = test_agent_class.new
      aggregate_failures do
        expect(agent.tools).to be_an(Array)
        expect(agent.tools.first).to be_a(TestTool)
      end
    end

    it 'loads external tool classes' do
      agent_class = create_agent_with_external_tool
      agent = agent_class.new
      expect_external_tool_loaded(agent)
    end

    def create_agent_with_external_tool
      stub_const('ExternalTool', Class.new(Soka::AgentTool))
      Class.new(described_class) do
        tool ExternalTool
      end
    end

    def expect_external_tool_loaded(agent)
      expect(agent.tools).to be_an(Array)
      expect(agent.tools.first).to be_an(ExternalTool)
    end

    it 'supports conditional tool loading' do
      agent_class = create_agent_with_conditional_tool
      agent = agent_class.new
      expect(agent.tools).to be_empty
    end

    def create_agent_with_conditional_tool
      stub_const('ConditionalTool', Class.new(Soka::AgentTool))
      Class.new(described_class) do
        provider :gemini
        api_key 'test-key'
        tool ConditionalTool, if: -> { false }
      end
    end
  end

  describe '.max_iterations' do
    it 'sets maximum iterations' do
      agent_class = create_agent_with_max_iterations(5)
      expect(agent_class._max_iterations).to eq(5)
    end

    def create_agent_with_max_iterations(value)
      Class.new(described_class) do
        max_iterations value
      end
    end
  end

  describe '.instructions' do
    it 'sets custom instructions' do
      agent_class = create_agent_with_instructions
      expect(agent_class._instructions).to eq('Custom system prompt')
    end

    def create_agent_with_instructions
      Class.new(described_class) do
        instructions 'Custom system prompt'
      end
    end
  end

  describe '.retry_config' do
    it 'configures retry settings' do
      agent_class = create_agent_with_retry_config
      expect_retry_configuration(agent_class)
    end

    def create_agent_with_retry_config
      Class.new(described_class) do
        retry_config do
          self.max_retries = 5
          self.backoff_strategy = :exponential
          retry_on << StandardError
        end
      end
    end

    def expect_retry_configuration(agent_class)
      retry_config = agent_class._retry_config
      aggregate_failures do
        expect(retry_config[:max_retries]).to eq(5)
        expect(retry_config[:backoff_strategy]).to eq(:exponential)
        expect(retry_config[:retry_on]).to include(StandardError)
      end
    end
  end

  describe 'hooks' do
    it 'executes before_action hooks' do
      agent_class = create_agent_with_before_hook
      agent = agent_class.new
      mock_llm_response(agent)

      agent.run('test input')
      expect(agent.instance_variable_get(:@before_called)).to be true
    end

    def create_agent_with_before_hook
      Class.new(described_class) do
        before_action :mark_before_called

        def mark_before_called(_input)
          @before_called = true
        end
      end
    end

    it 'executes after_action hooks' do
      agent_class = create_agent_with_after_hook
      agent = agent_class.new
      mock_llm_response(agent)

      result = agent.run('test input')
      expect(agent.instance_variable_get(:@after_result)).to eq(result)
    end

    def create_agent_with_after_hook
      Class.new(described_class) do
        after_action :save_after_result

        def save_after_result(result)
          @after_result = result
        end
      end
    end

    it 'executes on_error hooks' do
      agent = create_agent_with_error_hook.new
      mock_llm_error(agent)
      agent.run('test input')
      expect(agent.instance_variable_get(:@error_handled)).to be true
    end

    def create_agent_with_error_hook
      Class.new(described_class) do
        provider :gemini
        model 'test-model'
        api_key 'test-key'

        on_error :error_handler

        def error_handler(_error, _input)
          @error_handled = true
          :continue
        end
      end
    end

    def expect_error_result_type(result)
      expect(result).to be_a(Soka::Result)
      expect(result.successful?).to be false
    end
  end

  describe '#initialize' do
    it 'creates agent with default settings' do
      agent = test_agent_class.new
      expect_default_agent_state(agent)
      expect_agent_dependencies(agent)
    end

    def expect_agent_dependencies(agent)
      expect(agent.llm).to be_a(Soka::LLM)
      expect(agent.tools).to be_an(Array)
    end

    def expect_default_agent_state(agent)
      expect(agent.memory).to be_a(Soka::Memory)
      expect(agent.thoughts_memory).to be_a(Soka::ThoughtsMemory)
      expect(agent.engine).to eq(Soka::Engines::React)
    end

    it 'accepts custom memory' do
      custom_memory = Soka::Memory.new
      agent = test_agent_class.new(memory: custom_memory)
      expect(agent.memory).to eq(custom_memory)
    end

    it 'accepts custom engine' do
      custom_engine = Class.new(Soka::Engines::Base)
      agent = test_agent_class.new(engine: custom_engine)
      expect(agent.engine).to eq(custom_engine)
    end

    it 'accepts configuration options' do
      agent = create_agent_with_options
      expect_custom_configuration(agent)
    end

    def create_agent_with_options
      test_agent_class.new(
        max_iterations: 20
      )
    end

    def expect_custom_configuration(agent)
      aggregate_failures do
        expect(agent.instance_variable_get(:@max_iterations)).to eq(20)
      end
    end

    it 'accepts custom instructions at runtime' do
      agent = test_agent_class.new(instructions: 'Runtime custom instructions')
      expect(agent.instructions).to eq('Runtime custom instructions')
    end

    it 'uses class-level instructions when not provided at runtime' do
      agent_class = create_agent_class_with_instructions('Class-level instructions')
      agent = agent_class.new
      expect(agent.instructions).to eq('Class-level instructions')
    end

    def create_agent_class_with_instructions(instruction_text)
      Class.new(described_class) do
        provider :gemini
        model 'test-model'
        api_key 'test-key'
        instructions instruction_text
      end
    end

    it 'overrides class-level instructions with runtime instructions' do
      agent_class = create_agent_class_with_instructions('Class-level instructions')
      agent = agent_class.new(instructions: 'Runtime instructions override')
      expect(agent.instructions).to eq('Runtime instructions override')
    end
  end

  describe '#run' do
    let(:agent) { test_agent_class.new }

    context 'with valid input' do
      it 'returns successful result' do
        mock_llm_response(agent)
        result = agent.run('What is the weather?')
        expect_successful_result(result)
      end

      def expect_successful_result(result)
        aggregate_failures do
          expect(result).to be_a(Soka::Result)
          expect(result.successful?).to be true
          expect(result.final_answer).to include('sunny')
        end
      end

      it 'yields events during execution' do
        mock_event_responses(agent)
        events = collect_events_during_run(agent)
        expect_events_emitted(events)
      end

      def mock_event_responses(agent)
        lang_detect = Soka::LLMs::Result.new(content: 'en')
        response1 = create_tool_response
        response2 = create_final_answer
        allow(agent.llm).to receive(:chat).and_return(lang_detect, response1, response2)
      end

      def create_tool_response
        Soka::LLMs::Result.new(content: <<~RESPONSE)
          <Thought>Processing request</Thought>
          <Action>
          {"tool": "test_tool", "parameters": {"query": "test"}}
          </Action>
        RESPONSE
      end

      def create_final_answer
        Soka::LLMs::Result.new(content: '<FinalAnswer>The weather is sunny.</FinalAnswer>')
      end

      def collect_events_during_run(agent)
        events = []
        agent.run('test') { |event| events << event }
        events
      end

      def expect_events_emitted(events)
        event_types = events.map { |e| e[:type] }
        expect(event_types).to include(:thought, :action, :observation, :final_answer)
      end
    end

    context 'with invalid input' do
      it 'raises ArgumentError for empty input' do
        expect { agent.run('') }.to raise_error(ArgumentError, /Input cannot be empty/)
      end

      it 'raises ArgumentError for nil input' do
        expect { agent.run(nil) }.to raise_error(ArgumentError, /Input cannot be empty/)
      end
    end

    context 'with errors' do
      it 'handles LLM errors gracefully' do
        mock_llm_error(agent)
        result = agent.run('test')
        expect_error_result(result)
      end

      def expect_error_result(result)
        aggregate_failures do
          expect(result.successful?).to be false
          expect(result.error).to include('LLM request failed')
        end
      end
    end
  end

  describe 'memory management' do
    let(:agent) { test_agent_class.new }

    it 'updates memory after successful run' do
      mock_llm_response(agent)
      agent.run('Hello')

      expect_memory_updated(agent.memory)
    end

    def expect_memory_updated(memory)
      messages = memory.messages
      aggregate_failures do
        expect(messages.size).to be >= 2
        expect(messages.first[:content]).to eq('Hello')
        expect(messages.last[:role]).to eq('assistant')
      end
    end

    it 'records thoughts in thoughts_memory' do
      mock_llm_response(agent)
      agent.run('Test query')

      expect_thoughts_recorded(agent.thoughts_memory)
    end

    def expect_thoughts_recorded(thoughts_memory)
      sessions = thoughts_memory.all_sessions
      expect(sessions).not_to be_empty
      expect(sessions.first[:thoughts]).not_to be_empty
    end
  end
end
