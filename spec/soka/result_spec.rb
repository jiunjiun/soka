# frozen_string_literal: true

RSpec.describe Soka::Result do
  describe '#initialize' do
    it 'creates result with default values' do
      result = described_class.new
      expect_default_values(result)
    end

    def expect_default_values(result)
      expect_default_inputs(result)
      expect_default_outputs(result)
      expect_default_metadata(result)
    end

    def expect_default_inputs(result)
      expect(result.input).to be_nil
      expect(result.thoughts).to eq([])
    end

    def expect_default_outputs(result)
      expect(result.final_answer).to be_nil
    end

    def expect_default_metadata(result)
      expect(result.status).to eq(:pending)
      expect(result.error).to be_nil
      expect(result.execution_time).to be_nil
    end

    it 'creates result with provided attributes' do
      result = create_full_result
      expect_full_attributes(result)
    end

    def create_full_result
      described_class.new(
        input: 'Test input',
        thoughts: [{ type: :thought, content: 'Thinking...' }],
        final_answer: 'The answer is 42',
        status: :success,
        execution_time: 1.5
      )
    end

    def expect_full_attributes(result)
      expect_input_data(result)
      expect_output_data(result)
      expect_status_data(result)
    end

    def expect_input_data(result)
      expect(result.input).to eq('Test input')
      expect(result.thoughts.length).to eq(1)
    end

    def expect_output_data(result)
      expect(result.final_answer).to eq('The answer is 42')
    end

    def expect_status_data(result)
      expect(result.status).to eq(:success)
      expect(result.error).to be_nil
      expect(result.execution_time).to eq(1.5)
    end
  end

  describe 'status check methods' do
    describe '#successful?' do
      it 'returns true for success status' do
        result = described_class.new(status: :success)
        expect(result).to be_successful
      end

      it 'returns false for other statuses' do
        expect_not_successful(:failed)
        expect_not_successful(:timeout)
        expect_not_successful(:pending)
      end

      def expect_not_successful(status)
        result = described_class.new(status: status)
        expect(result).not_to be_successful
      end
    end

    describe '#failed?' do
      it 'returns true for failed status' do
        result = described_class.new(status: :failed)
        expect(result).to be_failed
      end

      it 'returns false for other statuses' do
        result = described_class.new(status: :success)
        expect(result).not_to be_failed
      end
    end

    describe '#timeout?' do
      it 'returns true for timeout status' do
        result = described_class.new(status: :timeout)
        expect(result).to be_timeout
      end

      it 'returns false for other statuses' do
        result = described_class.new(status: :success)
        expect(result).not_to be_timeout
      end
    end

    describe '#max_iterations_reached?' do
      it 'returns true for max_iterations_reached status' do
        result = described_class.new(status: :max_iterations_reached)
        expect(result).to be_max_iterations_reached
      end

      it 'returns false for other statuses' do
        result = described_class.new(status: :success)
        expect(result).not_to be_max_iterations_reached
      end
    end
  end

  describe '#iterations' do
    it 'returns count of thoughts' do
      result = create_result_with_thoughts(3)
      expect(result.iterations).to eq(3)
    end

    def create_result_with_thoughts(count)
      thoughts = count.times.map { |i| { type: :thought, content: "Thought #{i}" } }
      described_class.new(thoughts: thoughts)
    end

    it 'returns 0 for empty thoughts' do
      result = described_class.new(thoughts: [])
      expect(result.iterations).to eq(0)
    end

    it 'returns 0 for nil thoughts' do
      result = described_class.new(thoughts: nil)
      expect(result.iterations).to eq(0)
    end
  end

  describe '#to_h' do
    it 'returns complete hash for full result' do
      result = create_complete_result
      hash = result.to_h

      expect_complete_hash(hash)
    end

    def create_complete_result
      described_class.new(
        input: 'What is AI?',
        thoughts: [
          { type: :thought, content: 'AI is artificial intelligence' }
        ],
        final_answer: 'AI stands for Artificial Intelligence',
        status: :success,
        execution_time: 0.75
      )
    end

    def expect_complete_hash(hash)
      expect_hash_content(hash)
      expect_hash_metrics(hash)
      expect_hash_metadata(hash)
    end

    def expect_hash_content(hash)
      expect(hash[:input]).to eq('What is AI?')
      expect(hash[:thoughts]).to be_an(Array)
      expect(hash[:final_answer]).to eq('AI stands for Artificial Intelligence')
    end

    def expect_hash_metrics(hash)
      expect(hash[:execution_time]).to eq(0.75)
      expect(hash[:iterations]).to eq(1)
    end

    def expect_hash_metadata(hash)
      expect(hash[:status]).to eq(:success)
      expect(hash[:created_at]).to be_a(Time)
    end

    it 'excludes nil values from hash' do
      result = described_class.new(status: :success)
      hash = result.to_h

      expect(hash).not_to have_key(:error)
    end
  end

  describe '#to_json' do
    it 'converts to JSON string' do
      result = create_json_result
      json = result.to_json
      parsed = JSON.parse(json)
      expect_valid_json(parsed)
    end

    def create_json_result
      described_class.new(
        input: 'Test',
        status: :success,
        final_answer: 'Answer'
      )
    end

    def expect_valid_json(parsed)
      aggregate_failures do
        expect(parsed['input']).to eq('Test')
        expect(parsed['status']).to eq('success')
        expect(parsed['final_answer']).to eq('Answer')
      end
    end
  end

  describe '#summary' do
    it 'returns success message' do
      result = create_successful_result
      aggregate_failures do
        expect(result.summary).to include('Success:')
        expect(result.summary).to include('The answer is')
      end
    end

    def create_successful_result
      described_class.new(
        status: :success,
        final_answer: 'The answer is 42'
      )
    end

    it 'returns failure message' do
      result = create_failed_result
      expect(result.summary).to eq('Failed: Network error')
    end

    def create_failed_result
      described_class.new(
        status: :failed,
        error: 'Network error'
      )
    end

    it 'returns timeout message' do
      result = described_class.new(status: :timeout)
      expect(result.summary).to eq('Timeout: Execution exceeded time limit')
    end

    it 'returns max iterations message' do
      result = create_max_iterations_result
      expect(result.summary).to eq('Max iterations reached: 10 iterations')
    end

    def create_max_iterations_result
      thoughts = 10.times.map { { type: :thought } }
      described_class.new(
        status: :max_iterations_reached,
        thoughts: thoughts
      )
    end

    it 'truncates long answers' do
      result = create_result_with_long_answer
      aggregate_failures do
        expect(result.summary).to include('...')
        expect(result.summary.length).to be <= 120
      end
    end

    def create_result_with_long_answer
      long_answer = 'A' * 150
      described_class.new(
        status: :success,
        final_answer: long_answer
      )
    end

    it 'handles unknown status' do
      result = described_class.new(status: :unknown)
      expect(result.summary).to eq('Status: unknown')
    end
  end

  describe '#execution_details' do
    it 'returns detailed execution information' do
      result = create_result_with_execution_details
      details = result.execution_details

      expect_execution_details(details)
    end

    def create_result_with_execution_details
      described_class.new(
        thoughts: [{ type: :thought }, { type: :action }],
        execution_time: 2.345,
        status: :success
      )
    end

    def expect_execution_details(details)
      aggregate_failures do
        expect(details[:iterations]).to eq(2)
        expect(details[:time]).to eq('2.35s')
        expect(details[:status]).to eq(:success)
      end
    end

    it 'handles missing execution time' do
      result = described_class.new
      details = result.execution_details

      expect(details[:time]).to eq('N/A')
    end
  end

  describe 'edge cases' do
    it 'handles nil final answer in summary' do
      result = described_class.new(status: :success, final_answer: nil)
      expect(result.summary).to eq('Success: ')
    end

  end
end
