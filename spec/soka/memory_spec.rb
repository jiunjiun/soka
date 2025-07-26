# frozen_string_literal: true

RSpec.describe Soka::Memory do
  describe '#add' do
    it 'adds messages to memory' do
      memory = create_memory_with_messages
      expect_memory_contents(memory)
    end

    def create_memory_with_messages
      described_class.new.tap do |memory|
        memory.add(role: 'user', content: 'Hello')
        memory.add(role: 'assistant', content: 'Hi there!')
      end
    end

    def expect_memory_contents(memory)
      aggregate_failures do
        expect(memory.size).to eq(2)
        expect(memory.messages.first[:role]).to eq('user')
        expect(memory.messages.last[:content]).to eq('Hi there!')
      end
    end

    it 'validates role' do
      memory = described_class.new

      expect do
        memory.add(role: 'invalid', content: 'test')
      end.to raise_error(Soka::MemoryError, /Invalid role/)
    end

    it 'validates content' do
      memory = described_class.new

      expect do
        memory.add(role: 'user', content: '')
      end.to raise_error(Soka::MemoryError, /cannot be nil or empty/)
    end
  end

  describe '#to_messages' do
    it 'returns messages without timestamps' do
      memory = create_memory_with_test_message
      expect_messages_without_timestamps(memory)
    end

    def create_memory_with_test_message
      described_class.new.tap { |m| m.add(role: 'user', content: 'Test') }
    end

    def expect_messages_without_timestamps(memory)
      messages = memory.to_messages
      aggregate_failures do
        expect(messages).to eq([{ role: 'user', content: 'Test' }])
        expect(messages.first).not_to have_key(:timestamp)
      end
    end
  end
end
