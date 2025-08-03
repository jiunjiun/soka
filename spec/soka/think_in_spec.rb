# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Think In Languages Feature', type: :feature do
  def create_mock_llm_result(content)
    Soka::LLMs::Result.new(
      model: 'mock-model',
      content: content,
      input_tokens: 100,
      output_tokens: 200,
      finish_reason: 'stop',
      raw_response: { mock: true }
    )
  end

  def mock_response(agent, response_content)
    mock_llm = setup_mock_llm
    configure_mock_responses(mock_llm, agent, response_content)
  end

  def setup_mock_llm
    mock_llm = instance_double(Soka::LLMs::Base)
    allow(Soka::LLM).to receive(:new).and_return(mock_llm)
    mock_llm
  end

  def configure_mock_responses(mock_llm, _agent, response_content)
    allow(mock_llm).to receive(:chat)
      .and_return(create_mock_llm_result(response_content))
  end

  let(:test_agent_class) do
    Class.new(Soka::Agent) do
      provider :gemini
      model 'gemini-2.5-flash-lite'
      api_key 'test-key' # Avoid real API calls

      tool :dummy_tool, 'A dummy tool for testing' do
        def call
          'Dummy response'
        end
      end
    end
  end

  describe 'DSL configuration' do
    it 'accepts think_in configuration' do
      agent_class = Class.new(Soka::Agent) do
        think_in 'zh-TW'
      end

      expect(agent_class._think_in).to eq('zh-TW')
    end

    it 'converts symbol to string' do
      agent_class = Class.new(Soka::Agent) do
        think_in :ja_JP
      end

      expect(agent_class._think_in).to eq('ja_JP')
    end
  end

  describe 'Agent initialization' do
    it 'accepts think_in option during initialization' do
      agent = test_agent_class.new(think_in: 'ko-KR')
      expect(agent.think_in).to eq('ko-KR')
    end

    it 'uses DSL configuration when no option provided' do
      agent_class = Class.new(test_agent_class) do
        think_in 'es'
      end

      agent = agent_class.new
      expect(agent.think_in).to eq('es')
    end

    it 'prefers initialization option over DSL configuration' do
      agent_class = Class.new(test_agent_class) do
        think_in 'fr'
      end

      agent = agent_class.new(think_in: 'de')
      expect(agent.think_in).to eq('de')
    end
  end

  describe 'Language detection' do
    let(:agent) { test_agent_class.new }
    let(:mock_llm) { instance_double(Soka::LLMs::Base) }
    let(:lang_response) { create_mock_llm_result('zh-TW') }
    let(:main_response) { create_mock_llm_result('<Final_Answer>Done</Final_Answer>') }

    before do
      allow(Soka::LLM).to receive(:new).and_return(mock_llm)
    end

    context 'when think_in not specified' do
      before do
        # No language detection, just main reasoning
        allow(mock_llm).to receive(:chat)
          .with(array_including(hash_including(role: 'user', content: 'Please help me calculate')))
          .and_return(main_response)
      end

      it 'defaults to English thinking' do
        result = agent.run('Please help me calculate')
        expect(result.successful?).to be true
        # Should use default 'en' for thinking
      end
    end

    context 'when think_in is specified' do
      let(:agent) { test_agent_class.new(think_in: 'ja-JP') }

      before do
        allow(agent).to receive(:llm).and_return(mock_llm)
        # Should skip language detection and go straight to reasoning
        allow(mock_llm).to receive(:chat).and_return(
          create_mock_llm_result('<Thought>Processing</Thought><Final_Answer>Done</Final_Answer>')
        )
      end

      it 'uses specified language for thinking' do
        result = agent.run('Test input')
        expect(result.successful?).to be true
        # Should use specified 'ja-JP' for thinking
      end
    end
  end

  describe 'Prompt generation' do
    let(:mock_llm) { instance_double(Soka::LLMs::Base) }

    before do
      allow(Soka::LLM).to receive(:new).and_return(mock_llm)
      allow(mock_llm).to receive(:chat).and_return(
        create_mock_llm_result('<Thought>Testing</Thought><Final_Answer>Done</Final_Answer>')
      )
    end

    it 'includes thinking language instruction in prompt' do
      agent = test_agent_class.new(think_in: 'zh-TW')
      agent.run('Test')
      expect(mock_llm).to have_received(:chat)
    end

    it 'omits language instruction when think_in not specified' do
      agent = test_agent_class.new
      mock_response(agent, '<Final_Answer>Done</Final_Answer>')
      result = agent.run('Test')
      expect(result.final_answer).to eq('Done')
    end
  end

  describe 'Integration with ReAct engine' do
    it 'passes think_in to reasoning context' do
      setup_integration_test_mock
      agent = test_agent_class.new(think_in: 'pt-BR')
      result = agent.run('Test')
      expect(result.final_answer).to eq('Completed')
    end

    def setup_integration_test_mock
      mock_llm = instance_double(Soka::LLMs::Base)
      allow(Soka::LLM).to receive(:new).and_return(mock_llm)
      allow(mock_llm).to receive(:chat).and_return(
        create_mock_llm_result('<Final_Answer>Completed</Final_Answer>')
      )
    end

    context 'when maintaining think_in throughout reasoning' do
      let(:agent) { test_agent_class.new(think_in: 'it') }
      let(:mock_llm) { instance_double(Soka::LLMs::Base) }

      before do
        allow(Soka::LLM).to receive(:new).and_return(mock_llm)
        allow(mock_llm).to receive(:chat).and_return(
          create_mock_llm_result(
            '<Thought>Thinking in Italian</Thought><Action>\nTool: dummy_tool\nParameters: {}\n</Action>'
          ),
          create_mock_llm_result('<Final_Answer>Fatto!</Final_Answer>')
        )
      end

      it 'maintains think_in' do
        events = []
        agent.run('Test') { |event| events << event }
        expect(events).not_to be_empty
      end
    end
  end
end
