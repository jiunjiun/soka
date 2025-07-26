# frozen_string_literal: true

RSpec.describe Soka::LLM do
  describe '#initialize' do
    it 'creates provider based on provider name' do
      llm = described_class.new(:gemini, api_key: 'test-key')
      expect(llm.provider).to be_a(Soka::LLMs::Gemini)
    end

    it 'uses configuration provider when none specified' do
      configure_openai_provider
      llm = described_class.new
      expect(llm.provider).to be_a(Soka::LLMs::OpenAI)
      Soka.reset!
    end

    def configure_openai_provider
      Soka.reset!
      Soka.configure do |config|
        config.ai do |ai|
          ai.provider = :openai
          ai.api_key = 'test-key'
        end
      end
    end

    it 'passes options to provider' do
      llm = described_class.new(:anthropic, model: 'claude-3', api_key: 'test-key')
      expect(llm.provider.model).to eq('claude-3')
    end

    it 'raises error for unknown provider' do
      expect do
        described_class.new(:unknown, api_key: 'test-key')
      end.to raise_error(Soka::LLMError, /Unknown LLM provider: unknown/)
    end
  end

  describe '#chat' do
    let(:llm) { described_class.new(:gemini, api_key: 'test-key') }
    let(:messages) { [{ role: 'user', content: 'Hello' }] }

    it 'delegates to provider' do
      allow(llm.provider).to receive(:chat).and_return(
        Soka::LLMs::Result.new(content: 'Response')
      )

      result = llm.chat(messages)
      expect(result.content).to eq('Response')
    end

    it 'passes additional parameters' do
      allow(llm.provider).to receive(:chat).and_return(
        Soka::LLMs::Result.new(content: 'Response')
      )

      llm.chat(messages, temperature: 0.5)
      expect(llm.provider).to have_received(:chat).with(messages, temperature: 0.5)
    end
  end

  describe '#streaming_chat' do
    let(:llm) { described_class.new(:openai, api_key: 'test-key') }
    let(:messages) { [{ role: 'user', content: 'Hello' }] }

    it 'delegates to provider' do
      allow(llm.provider).to receive(:streaming_chat)

      block = proc { |chunk| chunk }
      llm.streaming_chat(messages, &block)

      expect(llm.provider).to have_received(:streaming_chat).with(messages)
    end
  end

  describe '#supports_streaming?' do
    it 'returns true for providers that support streaming' do
      llm = described_class.new(:openai, api_key: 'test-key')
      allow(llm.provider).to receive(:supports_streaming?).and_return(true)

      expect(llm.supports_streaming?).to be true
    end

    it 'returns false for providers that do not support streaming' do
      llm = described_class.new(:gemini, api_key: 'test-key')
      allow(llm.provider).to receive(:supports_streaming?).and_return(false)

      expect(llm.supports_streaming?).to be false
    end
  end

  describe '#model' do
    it 'returns provider model' do
      llm = described_class.new(:gemini, model: 'gemini-pro', api_key: 'test-key')
      expect(llm.model).to eq('gemini-pro')
    end
  end

  describe '.build' do
    it 'builds from configuration object' do
      config = create_config(:anthropic, 'claude-3', 'test-key')
      llm = described_class.build(config)
      expect_built_llm(llm)
    end

    def create_config(provider, model, api_key)
      Struct.new(:provider, :model, :api_key).new(provider, model, api_key)
    end

    def expect_built_llm(llm)
      expect(llm.provider).to be_a(Soka::LLMs::Anthropic)
      expect(llm.model).to eq('claude-3')
    end

    it 'handles nil values in config' do
      config = create_config(:gemini, nil, 'test-key')
      llm = described_class.build(config)
      expect(llm.provider).to be_a(Soka::LLMs::Gemini)
    end
  end
end
