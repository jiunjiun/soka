# frozen_string_literal: true

RSpec.describe Soka::Engines::React do
  let(:test_context) do
    memory = Soka::Memory.new
    calculator = Class.new(Soka::AgentTool) do
      def self.tool_name
        'calculator'
      end

      def call(**params)
        # Simple calculator for test purposes
        case params[:expression]
        when '2+2' then '4'
        when '10 * 5' then '50'
        when '1/0' then 'Error: divided by 0'
        else "Unknown expression: #{params[:expression]}"
        end
      end
    end.new

    search = Class.new(Soka::AgentTool) do
      def self.tool_name
        'search'
      end

      def call(**params)
        "Results for: #{params[:query]}"
      end
    end.new

    {
      agent: instance_double(Soka::Agent, memory: memory),
      memory: memory,
      llm: instance_double(Soka::LLM),
      tools: [calculator, search],
      max_iterations: 5
    }
  end

  let(:engine) do
    described_class.new(test_context[:agent], test_context[:llm], test_context[:tools], test_context[:max_iterations])
  end

  describe '#reason' do
    context 'with successful reasoning' do
      it 'returns success result with final answer' do
        mock_successful_reasoning(test_context[:llm])
        result = engine.reason('What is 2+2?')

        expect_successful_result(result)
      end

      def mock_successful_reasoning(llm)
        allow(llm).to receive(:chat).and_return(
          create_calculator_response,
          create_final_answer_response
        )
      end

      def create_calculator_response
        Soka::LLMs::Result.new(content: <<~RESPONSE)
          <Thought>This is a simple math question. I need to calculate 2+2.</Thought>
          <Action>
          Tool: calculator
          Parameters: {"expression": "2+2"}
          </Action>
        RESPONSE
      end

      def create_final_answer_response
        Soka::LLMs::Result.new(content: <<~RESPONSE)
          <Final_Answer>The answer to 2+2 is 4.</Final_Answer>
        RESPONSE
      end

      def expect_successful_result(result)
        expect(result.status).to eq(:success)
        expect(result.final_answer).to eq('The answer to 2+2 is 4.')
        expect_result_metadata(result)
      end

      def expect_result_metadata(result)
        expect(result.thoughts).not_to be_empty
        expect(result.confidence_score).to be > 0.5
      end

      it 'emits events during reasoning' do
        mock_successful_reasoning(test_context[:llm])
        events = collect_reasoning_events

        expect_emitted_events(events)
      end

      def collect_reasoning_events
        events = []
        engine.reason('What is 2+2?') { |event| events << event }
        events
      end

      def expect_emitted_events(events)
        event_types = events.map(&:type)
        aggregate_failures do
          expect(event_types).to include(:thought)
          expect(event_types).to include(:action)
          expect(event_types).to include(:observation)
          expect(event_types).to include(:final_answer)
        end
      end
    end

    context 'with multiple iterations' do
      it 'handles multi-step reasoning' do
        mock_multi_step_reasoning(test_context[:llm])
        result = engine.reason('Complex task')

        expect_multi_step_result(result)
      end

      def mock_multi_step_reasoning(llm)
        allow(llm).to receive(:chat).and_return(
          create_search_step,
          create_final_step
        )
      end

      def create_search_step
        Soka::LLMs::Result.new(content: <<~STEP1)
          <Thought>I need to search for information first.</Thought>
          <Action>search</Action>
          <Action_Input>{"query": "complex topic"}</Action_Input>
        STEP1
      end

      def create_final_step
        Soka::LLMs::Result.new(content: <<~STEP2)
          <Observation>Results for: complex topic</Observation>
          <Thought>Now I have the information I need.</Thought>
          <Final_Answer>Based on my research, here's the answer.</Final_Answer>
        STEP2
      end

      def expect_multi_step_result(result)
        aggregate_failures do
          expect(result).to be_successful
          expect(result.thoughts.length).to be >= 2
          expect(result.final_answer).to include('Based on my research')
        end
      end
    end

    context 'with max iterations reached' do
      it 'returns max_iterations_reached status' do
        mock_no_final_answer(test_context[:llm])
        result = engine.reason('Impossible task')

        expect_max_iterations_result(result)
      end

      def mock_no_final_answer(llm)
        response = Soka::LLMs::Result.new(content: <<~THINKING)
          <Thought>I'm still thinking about this...</Thought>
          <Action>search</Action>
          <Action_Input>{"query": "more info"}</Action_Input>
        THINKING

        allow(llm).to receive(:chat).and_return(response)
      end

      def expect_max_iterations_result(result)
        aggregate_failures do
          expect(result.status).to eq(:max_iterations_reached)
          expect(result.final_answer).to include("couldn't complete")
          expect(result.confidence_score).to eq(0.0)
        end
      end
    end

    context 'with tool execution' do
      it 'executes calculator tool correctly' do
        mock_calculator_action(test_context[:llm])
        result = engine.reason('Calculate 10 * 5')

        expect(result.final_answer).to include('50')
      end

      def mock_calculator_action(llm)
        responses = [
          create_calc_action_response,
          create_calc_result_response
        ]
        allow(llm).to receive(:chat).and_return(*responses)
      end

      def create_calc_action_response
        Soka::LLMs::Result.new(content: <<~CALC)
          <Thought>I need to multiply 10 by 5.</Thought>
          <Action>calculator</Action>
          <Action_Input>{"expression": "10 * 5"}</Action_Input>
        CALC
      end

      def create_calc_result_response
        Soka::LLMs::Result.new(content: <<~RESULT)
          <Observation>50</Observation>
          <Final_Answer>10 * 5 = 50</Final_Answer>
        RESULT
      end

      it 'handles tool execution errors' do
        mock_tool_error(test_context[:llm])
        events = []
        engine.reason('Invalid calculation') { |e| events << e }

        expect_error_handling(events)
      end

      def mock_tool_error(llm)
        allow(llm).to receive(:chat).and_return(
          create_error_action,
          create_error_recovery
        )
      end

      def create_error_action
        Soka::LLMs::Result.new(content: <<~ERROR)
          <Thought>Let me calculate this.</Thought>
          <Action>
          Tool: calculator
          Parameters: {"expression": "1/0"}
          </Action>
        ERROR
      end

      def create_error_recovery
        Soka::LLMs::Result.new(content: <<~RECOVER)
          <Thought>The calculation failed due to division by zero.</Thought>
          <Final_Answer>Cannot divide by zero.</Final_Answer>
        RECOVER
      end

      def expect_error_handling(events)
        observation_event = events.find { |e| e.type == :observation }
        expect(observation_event.content).to include('Error')
      end
    end

    context 'with invalid tool' do
      it 'handles non-existent tool gracefully' do
        mock_invalid_tool(test_context[:llm])
        events = []
        result = engine.reason('Use unknown tool') { |e| events << e }

        expect_invalid_tool_handling(events, result)
      end

      def mock_invalid_tool(llm)
        allow(llm).to receive(:chat).and_return(
          create_invalid_tool_action,
          create_tool_recovery
        )
      end

      def create_invalid_tool_action
        Soka::LLMs::Result.new(content: <<~INVALID)
          <Thought>I'll use a special tool.</Thought>
          <Action>
          Tool: unknown_tool
          Parameters: {}
          </Action>
        INVALID
      end

      def create_tool_recovery
        Soka::LLMs::Result.new(content: <<~RECOVERY)
          <Final_Answer>I cannot use that tool as it doesn't exist.</Final_Answer>
        RECOVERY
      end

      def expect_invalid_tool_handling(events, result)
        observation = events.find { |e| e.type == :observation }
        aggregate_failures do
          expect(observation.content).to include("Tool 'unknown_tool' not found")
          expect(result).to be_successful
        end
      end
    end

    context 'with malformed responses' do
      it 'handles responses without proper tags' do
        mock_malformed_response(test_context[:llm])
        result = engine.reason('Malformed test')

        expect_malformed_handling(result)
      end

      def mock_malformed_response(llm)
        allow(llm).to receive(:chat).and_return(
          Soka::LLMs::Result.new(content: 'Just a plain response without tags'),
          Soka::LLMs::Result.new(content: '<Final_Answer>Fallback answer</Final_Answer>')
        )
      end

      def expect_malformed_handling(result)
        aggregate_failures do
          expect(result).to be_successful
          expect(result.final_answer).to eq('Fallback answer')
        end
      end
    end

    context 'with confidence score calculation' do
      it 'calculates higher confidence for fewer iterations' do
        mock_quick_answer(test_context[:llm])
        result = engine.reason('Quick question')

        expect(result.confidence_score).to be_within(0.01).of(0.8)
      end

      def mock_quick_answer(llm)
        allow(llm).to receive(:chat).and_return(
          Soka::LLMs::Result.new(content: <<~QUICK)
            <Thought>This is straightforward.</Thought>
            <Final_Answer>Quick answer</Final_Answer>
          QUICK
        )
      end

      it 'calculates lower confidence for more iterations' do
        mock_lengthy_reasoning(test_context[:llm])
        result = engine.reason('Complex question')

        expect(result.confidence_score).to be < 0.7
      end

      def mock_lengthy_reasoning(llm)
        responses = create_multiple_iterations
        final_response = create_final_response
        allow(llm).to receive(:chat).and_return(*responses, final_response)
      end

      def create_multiple_iterations
        Array.new(4) do
          Soka::LLMs::Result.new(content: <<~ITER)
            <Thought>Still thinking...</Thought>
            <Action>
            Tool: search
            Parameters: {"query": "more info"}
            </Action>
          ITER
        end
      end

      def create_final_response
        Soka::LLMs::Result.new(content: <<~FINAL)
          <Observation>Found something</Observation>
          <Final_Answer>Finally, the answer</Final_Answer>
        FINAL
      end
    end
  end

  describe 'ReasonResult struct' do
    it 'creates result with all attributes' do
      result = create_complete_result
      expect_valid_reason_result(result)
    end

    def create_complete_result
      described_class::ReasonResult.new(
        input: 'test input',
        thoughts: [{ thought: 'thinking' }],
        final_answer: 'answer',
        status: :success,
        error: nil,
        confidence_score: 0.85
      )
    end

    def expect_valid_reason_result(result)
      expect_result_attributes(result)
      expect_result_status(result)
    end

    def expect_result_attributes(result)
      expect(result.input).to eq('test input')
      expect(result.thoughts).to eq([{ thought: 'thinking' }])
      expect(result.final_answer).to eq('answer')
    end

    def expect_result_status(result)
      expect(result.status).to eq(:success)
      expect(result.error).to be_nil
      expect(result.confidence_score).to eq(0.85)
    end
  end
end
