# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Soka::Engines::Prompts do
  # Create a test class that includes the module
  let(:test_class) do
    Class.new do
      include Soka::Engines::Prompts

      attr_accessor :tools, :max_iterations, :think_in, :custom_instructions

      def initialize
        @tools = []
        @max_iterations = 10
        @think_in = nil
        @custom_instructions = nil
      end
    end
  end

  let(:instance) { test_class.new }

  describe '#system_prompt' do
    context 'without custom instructions' do
      it 'returns default ReAct prompt' do
        prompt = instance.send(:system_prompt)
        expect(prompt).to include('ReAct (Reasoning and Acting) framework')
      end
    end

    context 'with custom instructions' do
      before do
        instance.custom_instructions = 'Be helpful and friendly'
      end

      it 'includes custom instructions text' do
        prompt = instance.send(:system_prompt)
        expect(prompt).to include('Be helpful and friendly')
      end

      it 'includes custom behavior section' do
        prompt = instance.send(:system_prompt)
        expect(prompt).to include('CUSTOM BEHAVIOR INSTRUCTIONS')
      end
    end
  end

  describe '#step_format_example' do
    subject(:format) { instance.send(:step_format_example) }

    it 'includes thinking phase section' do
      expect(format).to include('THINKING PHASE')
    end

    it 'includes thought tag format' do
      expect(format).to include('<Thought>')
    end

    it 'includes word limit instruction' do
      expect(format).to include('MAXIMUM 30 WORDS')
    end

    it 'includes action phase section' do
      expect(format).to include('ACTION PHASE')
    end

    it 'includes action tag format' do
      expect(format).to include('<Action>')
    end
  end

  describe '#xml_tag_requirements' do
    subject(:requirements) { instance.send(:xml_tag_requirements) }

    it 'specifies mandatory XML structure' do
      expect(requirements).to include('MANDATORY XML STRUCTURE')
    end

    it 'lists required tags' do
      expect(requirements).to include('<Thought>, <Action>, <FinalAnswer>')
    end

    it 'includes thinking phase section' do
      expect(requirements).to include('THINKING PHASE')
    end

    it 'specifies word limit for thoughts' do
      expect(requirements).to include('MAXIMUM 30 WORDS per thought')
    end

    it 'includes final answer section' do
      expect(requirements).to include('FINAL ANSWER')
    end

    it 'specifies final answer tag format' do
      expect(requirements).to include('<FinalAnswer>...</FinalAnswer>')
    end
  end

  describe '#build_iteration_limit_warning' do
    context 'with max_iterations set' do
      it 'includes iteration limit text' do
        warning = instance.send(:build_iteration_limit_warning)
        expect(warning).to include('ITERATION LIMIT')
      end

      it 'includes specific iteration count' do
        warning = instance.send(:build_iteration_limit_warning)
        expect(warning).to include('10 iterations')
      end
    end

    context 'without max_iterations' do
      before { instance.max_iterations = nil }

      it 'returns empty string' do
        warning = instance.send(:build_iteration_limit_warning)
        expect(warning).to eq('')
      end
    end
  end

  describe '#build_thinking_instruction' do
    context 'with think_in language' do
      before { instance.think_in = 'zh-TW' }

      it 'includes thinking language text' do
        instruction = instance.send(:build_thinking_instruction, instance.think_in)
        expect(instruction).to include('THINKING LANGUAGE')
      end

      it 'includes specific language' do
        instruction = instance.send(:build_thinking_instruction, instance.think_in)
        expect(instruction).to include('zh-TW')
      end
    end

    context 'without think_in language' do
      it 'returns empty string' do
        instruction = instance.send(:build_thinking_instruction, nil)
        expect(instruction).to eq('')
      end
    end
  end

  describe '#format_tools_description' do
    context 'with no tools' do
      it 'returns no tools message' do
        description = instance.send(:format_tools_description, [])
        expect(description).to eq('No tools available.')
      end
    end

    context 'with tools' do
      # Create a test tool class for testing
      let(:test_tool_class) do
        Class.new do
          def self.to_h
            {
              name: 'calculator',
              description: 'Performs calculations',
              parameters: {
                properties: {
                  expression: { type: 'string', description: 'Math expression' }
                },
                required: ['expression']
              }
            }
          end
        end
      end

      let(:tool) do
        test_tool_class.new
      end

      it 'includes tool name' do
        description = instance.send(:format_tools_description, [tool])
        expect(description).to include('calculator')
      end

      it 'includes tool description' do
        description = instance.send(:format_tools_description, [tool])
        expect(description).to include('Performs calculations')
      end

      it 'includes parameter requirements' do
        description = instance.send(:format_tools_description, [tool])
        expect(description).to include('expression (required)')
      end
    end
  end
end
