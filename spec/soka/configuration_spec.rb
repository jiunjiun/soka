# frozen_string_literal: true

RSpec.describe Soka::Configuration do
  describe '#initialize' do
    it 'creates default configuration' do
      config = described_class.new
      expect_default_configuration(config)
    end

    def expect_default_configuration(config)
      aggregate_failures do
        expect_ai_defaults(config.ai)
        expect_performance_defaults(config.performance)
        expect_logging_defaults(config.logging)
        expect(config.tools).to eq([])
      end
    end

    def expect_ai_defaults(ai_config)
      expect(ai_config.provider).to eq(:gemini)
      expect(ai_config.model).to eq('gemini-2.5-flash-lite')
    end

    def expect_performance_defaults(perf_config)
      expect(perf_config.max_iterations).to eq(10)
      expect(perf_config.timeout).to eq(30)
    end

    def expect_logging_defaults(log_config)
      expect(log_config.level).to eq(:info)
    end
  end

  describe '#ai' do
    it 'yields AI configuration block' do
      config = configure_ai_provider
      expect_openai_configuration(config)
    end

    def configure_ai_provider
      described_class.new.tap do |config|
        config.ai do |ai|
          ai.provider = :openai
          ai.model = 'gpt-4'
        end
      end
    end

    def expect_openai_configuration(config)
      aggregate_failures do
        expect(config.ai.provider).to eq(:openai)
        expect(config.ai.model).to eq('gpt-4')
      end
    end
  end
end
