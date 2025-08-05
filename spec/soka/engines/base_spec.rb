# frozen_string_literal: true

RSpec.describe Soka::Engines::Base do
  let(:test_context) do
    memory = Soka::Memory.new
    tool = Class.new(Soka::AgentTool) do
      def self.tool_name
        'test'
      end

      def execute(**params)
        "Executed with: #{params}"
      end
    end.new

    {
      agent: instance_double(Soka::Agent, memory: memory),
      memory: memory,
      llm: instance_double(Soka::LLM),
      tools: [tool],
      max_iterations: 10,
      test_tool: tool
    }
  end

  let(:engine) do
    described_class.new(test_context[:agent], test_context[:tools],
                        llm: test_context[:llm],
                        max_iterations: test_context[:max_iterations])
  end

  describe '#initialize' do
    it 'stores provided components' do
      expect_initialized_attributes(engine)
    end

    def expect_initialized_attributes(engine)
      expect_engine_components(engine)
      expect_engine_config(engine)
    end

    def expect_engine_components(engine)
      expect(engine.agent).to eq(test_context[:agent])
      expect(engine.llm).to eq(test_context[:llm])
    end

    def expect_engine_config(engine)
      expect(engine.tools).to eq(test_context[:tools])
      expect(engine.max_iterations).to eq(test_context[:max_iterations])
    end
  end

  describe '#reason' do
    it 'raises NotImplementedError' do
      expect do
        engine.reason('Test task')
      end.to raise_error(NotImplementedError, /must implement #reason method/)
    end
  end

  describe '#find_tool' do
    it 'finds tool by name' do
      tool = engine.send(:find_tool, 'test')
      expect(tool).to eq(test_context[:test_tool])
    end

    it 'finds tool by symbol name' do
      tool = engine.send(:find_tool, :test)
      expect(tool).to eq(test_context[:test_tool])
    end

    it 'returns nil for non-existent tool' do
      tool = engine.send(:find_tool, 'nonexistent')
      expect(tool).to be_nil
    end

    it 'handles case-insensitive search' do
      tool = engine.send(:find_tool, 'TEST')
      expect(tool).to eq(test_context[:test_tool])
    end
  end

  describe '#execute_tool' do
    it 'executes existing tool' do
      result = engine.send(:execute_tool, 'test', { param: 'value' })
      expect_successful_execution(result)
    end

    def expect_successful_execution(result)
      expect(result).to match(/Executed with: \{:?param:?\s*(?:=>|:)\s*"value"\}/)
    end

    it 'raises error for non-existent tool' do
      expect do
        engine.send(:execute_tool, 'nonexistent')
      end.to raise_error(Soka::ToolError, /Tool not found: nonexistent/)
    end

    it 'passes empty params when none provided' do
      result = engine.send(:execute_tool, 'test')
      expect(result).to include('Executed with: {}')
    end
  end

  describe '#emit_event' do
    it 'yields event when block given' do
      event = capture_emitted_event(:thought, 'Test content')

      expect_valid_event(event)
    end

    def capture_emitted_event(type, content)
      captured = nil
      engine.send(:emit_event, type, content) { |e| captured = e }
      captured
    end

    def expect_valid_event(event)
      aggregate_failures do
        expect(event.type).to eq(:thought)
        expect(event.content).to eq('Test content')
        expect(event).to respond_to(:type)
        expect(event).to respond_to(:content)
      end
    end

    it 'does nothing when no block given' do
      expect do
        engine.send(:emit_event, :thought, 'Test')
      end.not_to raise_error
    end
  end

  describe '#build_messages' do
    it 'builds messages with system prompt' do
      messages = engine.send(:build_messages, 'Test task')

      expect_system_message_present(messages)
    end

    def expect_system_message_present(messages)
      system_message = messages.first
      aggregate_failures do
        expect(system_message[:role]).to eq('system')
        expect(system_message[:content]).to eq('You are a helpful AI assistant.')
      end
    end

    it 'includes memory messages when available' do
      add_memory_messages(test_context[:memory])
      messages = engine.send(:build_messages, 'New task')

      expect_memory_messages_included(messages)
    end

    def add_memory_messages(memory)
      memory.add(role: 'user', content: 'Previous question')
      memory.add(role: 'assistant', content: 'Previous answer')
    end

    def expect_memory_messages_included(messages)
      expect(messages.size).to eq(4)
      expect_memory_content(messages)
    end

    def expect_memory_content(messages)
      expect(messages[1][:content]).to eq('Previous question')
      expect(messages[2][:content]).to eq('Previous answer')
      expect(messages[3][:content]).to eq('New task')
    end

    it 'handles agent without memory' do
      engine_without_memory = create_engine_without_memory
      messages = engine_without_memory.send(:build_messages, 'Task')

      expect_no_memory_messages(messages)
    end

    def create_engine_without_memory
      agent_without_memory = instance_double(Soka::Agent, memory: nil)
      described_class.new(agent_without_memory, test_context[:tools],
                          llm: test_context[:llm],
                          max_iterations: test_context[:max_iterations])
    end

    def expect_no_memory_messages(messages)
      aggregate_failures do
        expect(messages.size).to eq(2)
        expect(messages[0][:role]).to eq('system')
        expect(messages[1][:role]).to eq('user')
      end
    end
  end

  describe '#system_message' do
    it 'returns system role message' do
      message = engine.send(:system_message)
      expect_valid_system_message(message)
    end

    def expect_valid_system_message(message)
      aggregate_failures do
        expect(message[:role]).to eq('system')
        expect(message[:content]).to be_a(String)
      end
    end
  end

  describe '#user_message' do
    it 'returns user role message' do
      message = engine.send(:user_message, 'User input')
      expect_valid_user_message(message)
    end

    def expect_valid_user_message(message)
      aggregate_failures do
        expect(message[:role]).to eq('user')
        expect(message[:content]).to eq('User input')
      end
    end
  end

  describe '#system_prompt' do
    it 'returns default system prompt' do
      prompt = engine.send(:system_prompt)
      expect(prompt).to eq('You are a helpful AI assistant.')
    end
  end

  describe 'subclass implementation' do
    let(:custom_engine_class) do
      Class.new(described_class) do
        def reason(task)
          emit_event(:custom, 'Custom reasoning') { |e| e }
          Soka::Result.new(
            input: task,
            final_answer: 'Custom answer',
            status: :success
          )
        end

        protected

        def system_prompt
          'Custom system prompt'
        end
      end
    end

    let(:custom_engine) do
      custom_engine_class.new(test_context[:agent], test_context[:tools],
                              llm: test_context[:llm],
                              max_iterations: test_context[:max_iterations])
    end

    it 'allows subclass to implement reason' do
      result = custom_engine.reason('Test')
      expect_custom_implementation(result)
    end

    def expect_custom_implementation(result)
      expect(result.input).to eq('Test')
      expect(result.final_answer).to eq('Custom answer')
      expect(result).to be_successful
    end

    it 'allows subclass to override system_prompt' do
      prompt = custom_engine.send(:system_prompt)
      expect(prompt).to eq('Custom system prompt')
    end
  end
end
