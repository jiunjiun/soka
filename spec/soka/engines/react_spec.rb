# frozen_string_literal: true

require 'spec_helper'

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
    described_class.new(test_context[:agent], test_context[:tools],
                        llm: test_context[:llm],
                        max_iterations: test_context[:max_iterations])
  end

  describe '#reason' do
    context 'with successful reasoning' do
      it 'returns success result with final answer' do
        mock_calculator_tool
        mock_successful_reasoning(test_context[:llm])
        result = engine.reason('What is 2+2?')
        expect_successful_result(result)
      end

      def mock_calculator_tool
        calculator = test_context[:tools].find { |t| t.class.tool_name == 'calculator' }
        allow(calculator).to receive(:execute).with(expression: '2+2').and_return('4')
      end

      def mock_successful_reasoning(llm)
        # Use and_return with multiple values for sequential calls
        responses = [
          Soka::LLMs::Result.new(content: 'en'),  # Language detection
          create_calculator_response,
          create_final_answer_response
        ]
        allow(llm).to receive(:chat).and_return(*responses)
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
        responses = [
          Soka::LLMs::Result.new(content: 'en'),  # Language detection
          create_search_step,
          create_final_step
        ]
        allow(llm).to receive(:chat).and_return(*responses)
      end

      def create_search_step
        Soka::LLMs::Result.new(content: <<~STEP1)
          <Thought>I need to search for information first.</Thought>
          <Action>
          Tool: search
          Parameters: {"query": "complex topic"}
          </Action>
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
        thinking_response = create_thinking_response
        responses = build_no_final_answer_responses(thinking_response)
        allow(llm).to receive(:chat).and_return(*responses)
      end

      def create_thinking_response
        Soka::LLMs::Result.new(content: <<~THINKING)
          <Thought>I'm still thinking about this...</Thought>
          <Action>
          Tool: search
          Parameters: {"query": "more info"}
          </Action>
        THINKING
      end

      def build_no_final_answer_responses(thinking_response)
        responses = []
        responses << Soka::LLMs::Result.new(content: 'en') # Language detection
        6.times { responses << thinking_response } # Return same response for all iterations
        responses
      end

      def expect_max_iterations_result(result)
        aggregate_failures do
          expect(result.status).to eq(:max_iterations_reached)
          expect(result.final_answer).to include("couldn't complete")
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
          Soka::LLMs::Result.new(content: 'en'),  # Language detection
          create_calc_action_response,
          create_calc_result_response
        ]
        allow(llm).to receive(:chat).and_return(*responses)
      end

      def create_calc_action_response
        Soka::LLMs::Result.new(content: <<~CALC)
          <Thought>I need to multiply 10 by 5.</Thought>
          <Action>
          Tool: calculator
          Parameters: {"expression": "10 * 5"}
          </Action>
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
        responses = [
          Soka::LLMs::Result.new(content: 'en'),  # Language detection
          create_error_action,
          create_error_recovery
        ]
        allow(llm).to receive(:chat).and_return(*responses)
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
        responses = [
          Soka::LLMs::Result.new(content: 'en'),  # Language detection
          create_invalid_tool_action,
          create_tool_recovery
        ]
        allow(llm).to receive(:chat).and_return(*responses)
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
        error_event = events.find { |e| e[:type] == :error }
        aggregate_failures do
          expect(error_event).not_to be_nil
          expect(error_event[:content]).to include("Tool 'unknown_tool' not found")
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
        responses = [
          Soka::LLMs::Result.new(content: 'en'),  # Language detection
          Soka::LLMs::Result.new(content: 'Just a plain response without tags'),
          Soka::LLMs::Result.new(content: '<Final_Answer>Fallback answer</Final_Answer>')
        ]
        allow(llm).to receive(:chat).and_return(*responses)
      end

      def expect_malformed_handling(result)
        aggregate_failures do
          expect(result).to be_successful
          expect(result.final_answer).to eq('Fallback answer')
        end
      end
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

    context 'with custom instructions' do
      let(:engine_with_instructions) do
        described_class.new(test_context[:agent], test_context[:tools],
                            llm: test_context[:llm],
                            max_iterations: test_context[:max_iterations],
                            custom_instructions: 'You are a helpful assistant with custom behavior')
      end
      let(:messages_sent) { [] }

      before do
        call_count = 0
        allow(test_context[:llm]).to receive(:chat) do |messages|
          call_count += 1
          if call_count == 1 # Language detection
            Soka::LLMs::Result.new(content: 'en')
          else
            messages_sent.replace(messages)
            Soka::LLMs::Result.new(content: '<Final_Answer>Test response</Final_Answer>')
          end
        end
      end

      it 'initializes with custom instructions' do
        expect(engine_with_instructions.custom_instructions).to eq('You are a helpful assistant with custom behavior')
      end

      it 'includes custom instructions in system prompt' do
        engine_with_instructions.reason('Test query')

        system_message = messages_sent.find { |m| m[:role] == 'system' }
        expect(system_message[:content]).to include('You are a helpful assistant with custom behavior')
      end

      it 'maintains standard ReAct format in system prompt' do
        engine_with_instructions.reason('Test query')

        system_message = messages_sent.find { |m| m[:role] == 'system' }
        expect(system_message[:content]).to include('You have access to the following tools')
      end

      it 'includes exact format instruction in system prompt' do
        engine_with_instructions.reason('Test query')

        system_message = messages_sent.find { |m| m[:role] == 'system' }
        expect(system_message[:content]).to include('You must follow this exact format')
      end

      it 'uses default instructions without custom ones' do
        engine.reason('Test query')

        system_message = messages_sent.find { |m| m[:role] == 'system' }
        expect(system_message[:content]).to include('You are an AI assistant that uses the ReAct')
      end

      it 'does not include custom instructions when not specified' do
        engine.reason('Test query')

        system_message = messages_sent.find { |m| m[:role] == 'system' }
        expect(system_message[:content]).not_to include('You are a helpful assistant with custom behavior')
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
        error: nil
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
    end
  end
end
