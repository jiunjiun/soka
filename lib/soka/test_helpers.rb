# frozen_string_literal: true

module Soka
  # RSpec test helpers for Soka framework
  module TestHelpers
    def self.included(base)
      base.class_eval do
        let(:mock_llm_response) { nil }
        let(:mock_tool_responses) { {} }
      end
    end

    def mock_ai_response(response_data)
      @mock_llm_response = response_data

      # Create a mock LLM that returns the specified response
      mock_llm = instance_double(Soka::LLM::Base)

      # Format the response content based on the response data
      content = build_react_content(response_data)

      result = create_mock_llm_result(content)

      allow(mock_llm).to receive(:chat).and_return(result)
      allow(Soka::LLM).to receive(:new).and_return(mock_llm)

      mock_llm
    end

    def create_mock_llm_result(content)
      Soka::LLM::Result.new(
        model: 'mock-model',
        content: content,
        input_tokens: 100,
        output_tokens: 200,
        finish_reason: 'stop',
        raw_response: { mock: true }
      )
    end

    def mock_tool_response(tool_class, response)
      @mock_tool_responses[tool_class] = response

      # Create a mock instance of the tool
      mock_tool = instance_double(tool_class)
      allow(mock_tool).to receive(:class).and_return(tool_class)
      allow(mock_tool).to receive(:execute).and_return(response)

      # Allow the tool class to be instantiated with the mock
      allow(tool_class).to receive(:new).and_return(mock_tool)

      mock_tool
    end

    def allow_tool_to_fail(tool_class, error)
      mock_tool = instance_double(tool_class)
      allow(mock_tool).to receive(:class).and_return(tool_class)
      allow(mock_tool).to receive(:execute).and_raise(error)

      allow(tool_class).to receive(:new).and_return(mock_tool)

      mock_tool
    end

    def create_test_agent(options = {})
      Class.new(Soka::Agent) do
        provider :gemini
        model 'gemini-2.5-flash'
        max_iterations 5
        timeout 10
      end.new(**options)
    end

    def create_test_tool(name: 'test_tool', description: 'Test tool', &block)
      Class.new(Soka::AgentTool) do
        desc description

        define_singleton_method :tool_name do
          name
        end

        define_method :call, &block || -> { 'Test response' }
      end
    end

    def stub_env(env_vars)
      env_vars.each do |key, value|
        allow(ENV).to receive(:fetch).with(key).and_return(value)
        allow(ENV).to receive(:[]).with(key).and_return(value)
      end
    end

    def with_configuration
      original_config = Soka.configuration
      Soka.reset!
      yield
    ensure
      Soka.configuration = original_config
    end

    private

    def build_react_content(response_data)
      content = []

      # Build thoughts and actions
      response_data[:thoughts].each_with_index do |thought_data, _index|
        content << "<Thought>#{thought_data[:thought]}</Thought>"

        next unless thought_data[:action]

        action = thought_data[:action]
        params_json = action[:params].to_json

        content << build_action_content(action[:tool], params_json)

        # The observation will be added by the engine
      end

      # Add final answer if present
      content << "<Final_Answer>#{response_data[:final_answer]}</Final_Answer>" if response_data[:final_answer]

      content.join("\n")
    end

    def build_action_content(tool, params_json)
      <<~ACTION
        <Action>
        Tool: #{tool}
        Parameters: #{params_json}
        </Action>
      ACTION
    end

    # Matcher helpers for RSpec
    module Matchers
      def be_successful
        satisfy(&:successful?)
      end

      def be_failed
        satisfy(&:failed?)
      end

      def final_answer?(expected = nil)
        if expected
          satisfy { |result| result.final_answer == expected }
        else
          satisfy { |result| !result.final_answer.nil? }
        end
      end

      def thoughts_count?(count)
        satisfy { |result| result.thoughts.length == count }
      end

      def confidence_score_above?(threshold)
        satisfy { |result| result.confidence_score > threshold }
      end
    end
  end
end
