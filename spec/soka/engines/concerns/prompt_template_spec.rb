# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Soka::Engines::Concerns::PromptTemplate do
  # Create a test class that includes the module
  let(:test_class) do
    Class.new do
      include Soka::Engines::Concerns::PromptTemplate
      include Soka::Engines::Concerns::FormatHelpers
      include Soka::Engines::Concerns::TagFormat

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

  describe '#tag_restrictions' do
    it 'specifies only three allowed tags' do
      restrictions = instance.send(:tag_restrictions)
      expect(restrictions).to include('ONLY use these three tags: <Thought>, <Action>, <Final_Answer>')
    end

    it 'requires closing tags' do
      restrictions = instance.send(:tag_restrictions)
      expect(restrictions).to include('ALL tags MUST have both opening and closing tags')
    end
  end

  describe '#allowed_tags_format' do
    it 'includes thinking tag format' do
      format = instance.send(:allowed_tags_format)
      expect(format).to include('THINKING TAG')
    end

    it 'includes action tag format' do
      format = instance.send(:allowed_tags_format)
      expect(format).to include('ACTION TAG')
    end

    it 'includes final answer tag format' do
      format = instance.send(:allowed_tags_format)
      expect(format).to include('FINAL ANSWER TAG')
    end

    it 'specifies JSON requirement for Action' do
      format = instance.send(:allowed_tags_format)
      expect(format).to include('MUST contain ONLY valid JSON')
    end

    it 'specifies JSON format structure' do
      format = instance.send(:allowed_tags_format)
      expect(format).to include('{"tool": "name", "parameters": {...}}')
    end
  end

  describe '#build_iteration_limit_warning' do
    context 'when max_iterations is set' do
      before { instance.max_iterations = 5 }

      it 'includes iteration limit label' do
        warning = instance.send(:build_iteration_limit_warning)
        expect(warning).to include('ITERATION LIMIT')
      end

      it 'includes the maximum iterations count' do
        warning = instance.send(:build_iteration_limit_warning)
        expect(warning).to include('5 attempts maximum')
      end

      it 'mentions Final_Answer requirement' do
        warning = instance.send(:build_iteration_limit_warning)
        expect(warning).to include('Must provide <Final_Answer>')
      end
    end

    context 'when max_iterations is nil' do
      it 'returns empty string' do
        instance.max_iterations = nil
        warning = instance.send(:build_iteration_limit_warning)

        expect(warning).to eq('')
      end
    end
  end

  describe '#format_instructions' do
    context 'with max_iterations' do
      before { instance.max_iterations = 3 }

      it 'includes iteration limit at the beginning' do
        instructions = instance.send(:format_instructions)
        expect(instructions).to start_with('⏰ ITERATION LIMIT')
      end

      it 'includes the iteration count in instructions' do
        instructions = instance.send(:format_instructions)
        expect(instructions).to include('3 attempts maximum')
      end
    end

    context 'without max_iterations' do
      it 'does not include iteration limit' do
        instance.max_iterations = nil
        instructions = instance.send(:format_instructions)

        expect(instructions).not_to include('ITERATION LIMIT')
      end
    end

    it 'includes tag restrictions' do
      instructions = instance.send(:format_instructions)
      expect(instructions).to include('TAG RESTRICTIONS')
    end

    it 'includes workflow rules' do
      instructions = instance.send(:format_instructions)
      expect(instructions).to include('WORKFLOW RULES')
    end
  end

  describe '#system_prompt' do
    context 'with default react prompt' do
      it 'includes iteration warning when max_iterations is set' do
        instance.max_iterations = 7
        prompt = instance.send(:system_prompt)

        expect(prompt).to include('7 attempts maximum')
      end
    end

    context 'with custom instructions' do
      before do
        instance.max_iterations = 5
        instance.custom_instructions = 'You are a helpful assistant.'
      end

      it 'includes custom instructions' do
        prompt = instance.send(:system_prompt)
        expect(prompt).to include('You are a helpful assistant.')
      end

      it 'includes iteration warning with custom instructions' do
        prompt = instance.send(:system_prompt)
        expect(prompt).to include('5 attempts maximum')
      end
    end
  end
end
