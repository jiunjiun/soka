# frozen_string_literal: true

RSpec.describe Soka::ThoughtsMemory do
  let(:memory) { described_class.new }

  let(:successful_result) do
    Soka::Result.new(
      input: 'What is 2+2?',
      thoughts: [
        { type: :thought, content: 'This is a simple math problem' },
        { type: :action, content: 'Calculate: 2+2=4' },
        { type: :observation, content: 'The result is 4' }
      ],
      final_answer: '4',
      status: :success,
      confidence_score: 0.95,
      execution_time: 0.5
    )
  end

  let(:failed_result) do
    Soka::Result.new(
      input: 'Complex query',
      thoughts: [
        { type: :thought, content: 'This seems complex' }
      ],
      status: :failed,
      error: 'Unable to process query',
      confidence_score: 0.2,
      execution_time: 1.2
    )
  end

  describe '#initialize' do
    it 'creates empty sessions array' do
      aggregate_failures do
        expect(memory.sessions).to eq([])
        expect(memory).to be_empty
      end
    end
  end

  describe '#add' do
    it 'adds successful session' do
      memory.add('What is 2+2?', successful_result)
      expect_successful_session_added(memory.last_session)
    end

    def expect_successful_session_added(session)
      expect(session).to include(
        input: 'What is 2+2?',
        final_answer: '4',
        status: :success,
        confidence_score: 0.95,
        timestamp: a_kind_of(Time)
      )
      expect(session[:thoughts].length).to eq(3)
      expect(session).not_to have_key(:error)
    end

    it 'adds failed session with error' do
      memory.add('Complex query', failed_result)
      expect_failed_session_added(memory.last_session)
    end

    def expect_failed_session_added(session)
      aggregate_failures do
        expect(session[:input]).to eq('Complex query')
        expect(session[:status]).to eq(:failed)
        expect(session[:error]).to eq('Unable to process query')
        expect(session[:confidence_score]).to eq(0.2)
      end
    end

    it 'handles results without thoughts' do
      result = Soka::Result.new(final_answer: 'Answer', status: :success)
      memory.add('Query', result)

      expect(memory.last_session[:thoughts]).to eq([])
    end
  end

  describe '#last_session' do
    it 'returns the most recent session' do
      add_multiple_sessions(memory)
      expect_last_session_is_recent(memory.last_session)
    end

    def expect_last_session_is_recent(session)
      expect(session[:input]).to eq('Second')
    end

    it 'returns nil when empty' do
      expect(memory.last_session).to be_nil
    end
  end

  describe '#all_sessions' do
    it 'returns all sessions in order' do
      add_multiple_sessions(memory)
      sessions = memory.all_sessions

      expect_sessions_in_order(sessions)
    end

    def expect_sessions_in_order(sessions)
      aggregate_failures do
        expect(sessions.length).to eq(2)
        expect(sessions[0][:input]).to eq('First')
        expect(sessions[1][:input]).to eq('Second')
      end
    end
  end

  describe '#clear' do
    it 'removes all sessions' do
      add_multiple_sessions(memory)
      memory.clear

      expect_memory_cleared(memory)
    end

    def expect_memory_cleared(memory)
      aggregate_failures do
        expect(memory).to be_empty
        expect(memory.size).to eq(0)
        expect(memory.sessions).to eq([])
      end
    end
  end

  describe '#size and #empty?' do
    it 'tracks session count' do
      expect_initial_state(memory)

      memory.add('Query', successful_result)
      expect_single_session_state(memory)
    end

    def expect_initial_state(memory)
      aggregate_failures do
        expect(memory.size).to eq(0)
        expect(memory).to be_empty
      end
    end

    def expect_single_session_state(memory)
      aggregate_failures do
        expect(memory.size).to eq(1)
        expect(memory).not_to be_empty
      end
    end
  end

  # Helper methods moved outside describe blocks for reuse
  def create_another_successful_result
    Soka::Result.new(
      final_answer: 'Another answer',
      status: :success,
      confidence_score: 0.85
    )
  end

  def add_mixed_sessions(memory)
    memory.add('Success 1', successful_result)
    memory.add('Failure', failed_result)
    memory.add('Success 2', create_another_successful_result)
  end

  def add_multiple_sessions(memory)
    memory.add('First', successful_result)
    memory.add('Second', failed_result)
  end

  describe '#successful_sessions' do
    it 'filters successful sessions' do
      add_mixed_sessions(memory)
      successful = memory.successful_sessions

      expect_only_successful_sessions(successful)
    end

    def expect_only_successful_sessions(sessions)
      aggregate_failures do
        expect(sessions.length).to eq(2)
        expect(sessions).to all(include(status: :success))
      end
    end
  end

  describe '#failed_sessions' do
    it 'filters failed sessions' do
      add_mixed_sessions(memory)
      failed = memory.failed_sessions

      expect_only_failed_sessions(failed)
    end

    def expect_only_failed_sessions(sessions)
      aggregate_failures do
        expect(sessions.length).to eq(1)
        expect(sessions.first[:status]).to eq(:failed)
        expect(sessions.first[:input]).to eq('Failure')
      end
    end
  end

  describe '#average_confidence_score' do
    it 'calculates average for successful sessions' do
      add_sessions_with_scores(memory)

      expect(memory.average_confidence_score).to be_within(0.01).of(0.85)
    end

    def add_sessions_with_scores(memory)
      memory.add('High confidence', create_result_with_score(0.95))
      memory.add('Medium confidence', create_result_with_score(0.75))
      memory.add('Failed', create_failed_result_with_score(0.2))
    end

    def create_result_with_score(score)
      Soka::Result.new(status: :success, confidence_score: score)
    end

    def create_failed_result_with_score(score)
      Soka::Result.new(status: :failed, confidence_score: score)
    end

    it 'returns 0.0 when no successful sessions' do
      memory.add('Failed', failed_result)
      expect(memory.average_confidence_score).to eq(0.0)
    end

    it 'returns 0.0 when empty' do
      expect(memory.average_confidence_score).to eq(0.0)
    end
  end

  describe '#average_iterations' do
    it 'calculates average thought count' do
      add_sessions_with_different_iterations(memory)

      expect(memory.average_iterations).to eq(2.5)
    end

    def add_sessions_with_different_iterations(memory)
      memory.add('Many thoughts', create_result_with_thoughts(4))
      memory.add('Few thoughts', create_result_with_thoughts(1))
    end

    def create_result_with_thoughts(count)
      thoughts = count.times.map { |i| { type: :thought, content: "Thought #{i}" } }
      Soka::Result.new(thoughts: thoughts, status: :success)
    end

    it 'returns 0 when empty' do
      expect(memory.average_iterations).to eq(0)
    end
  end

  describe '#to_s and #inspect' do
    it 'shows summary when empty' do
      aggregate_failures do
        expect(memory.to_s).to eq('<Soka::ThoughtsMemory> (0 sessions)')
        expect(memory.inspect).to eq(memory.to_s)
      end
    end

    it 'shows detailed stats when has sessions' do
      populate_memory_with_sessions(memory)

      expect_detailed_stats_string(memory.to_s)
    end

    def populate_memory_with_sessions(memory)
      memory.add('Success 1', successful_result)
      memory.add('Success 2', create_another_successful_result)
      memory.add('Failure', failed_result)
    end

    def expect_detailed_stats_string(string)
      aggregate_failures do
        expect(string).to include('3 sessions')
        expect(string).to include('2 successful')
        expect(string).to include('1 failed')
        expect(string).to include('avg confidence:')
        expect(string).to include('avg iterations:')
      end
    end
  end

  describe '#to_h' do
    it 'returns hash representation' do
      memory.add('Test', successful_result)
      hash = memory.to_h

      expect_valid_hash_structure(hash)
    end

    def expect_valid_hash_structure(hash)
      aggregate_failures do
        expect(hash).to have_key(:sessions)
        expect(hash).to have_key(:stats)
        expect_stats_structure(hash[:stats])
      end
    end

    def expect_stats_structure(stats)
      expect(stats).to include(
        total_sessions: 1,
        successful_sessions: 1,
        failed_sessions: 0,
        average_confidence_score: 0.95,
        average_iterations: 3
      )
    end
  end

  describe 'edge cases' do
    it 'handles nil confidence scores' do
      result = Soka::Result.new(status: :success)
      memory.add('No confidence', result)

      expect(memory.average_confidence_score).to eq(0.0)
    end

    it 'handles sessions with no thoughts' do
      result = Soka::Result.new(thoughts: nil, status: :success)
      memory.add('No thoughts', result)

      expect(memory.average_iterations).to eq(0.0)
    end
  end
end
