# frozen_string_literal: true

require 'spec_helper'
require 'soka/llms/base'

RSpec.describe Soka::LLMs::Result do
  describe '#successful?' do
    it 'returns true when content is present' do
      result = described_class.new(content: 'Test response')
      expect(result).to be_successful
    end

    it 'returns false when content is nil' do
      result = described_class.new(content: nil)
      expect(result).not_to be_successful
    end

    it 'returns false when content is empty' do
      result = described_class.new(content: '')
      expect(result).not_to be_successful
    end
  end

  describe 'attributes' do
    it 'stores all provided attributes' do
      result = create_complete_result
      expect_all_attributes(result)
    end

    def create_complete_result
      described_class.new(
        model: 'gpt-4',
        content: 'Test response',
        input_tokens: 100,
        output_tokens: 200,
        finish_reason: 'stop',
        raw_response: { id: 'test-123' }
      )
    end

    def expect_all_attributes(result)
      expect_basic_attributes(result)
      expect_token_attributes(result)
      expect_meta_attributes(result)
    end

    def expect_basic_attributes(result)
      expect(result.model).to eq('gpt-4')
      expect(result.content).to eq('Test response')
    end

    def expect_token_attributes(result)
      expect(result.input_tokens).to eq(100)
      expect(result.output_tokens).to eq(200)
    end

    def expect_meta_attributes(result)
      expect(result.finish_reason).to eq('stop')
      expect(result.raw_response).to eq({ id: 'test-123' })
    end

    it 'allows nil attributes' do
      result = described_class.new
      expect_nil_attributes(result)
    end

    def expect_nil_attributes(result)
      expect_nil_basic_attrs(result)
      expect_nil_token_attrs(result)
      expect_nil_meta_attrs(result)
    end

    def expect_nil_basic_attrs(result)
      expect(result.model).to be_nil
      expect(result.content).to be_nil
    end

    def expect_nil_token_attrs(result)
      expect(result.input_tokens).to be_nil
      expect(result.output_tokens).to be_nil
    end

    def expect_nil_meta_attrs(result)
      expect(result.finish_reason).to be_nil
      expect(result.raw_response).to be_nil
    end
  end
end
