# frozen_string_literal: true

require 'zeitwerk'
require 'faraday'
require 'oj'

# Main module for the Soka ReAct Agent Framework
# Provides AI agent capabilities with multiple LLM providers support
module Soka
  class Error < StandardError; end
  class ConfigurationError < Error; end
  class LLMError < Error; end
  class ToolError < Error; end
  class AgentError < Error; end
  class MemoryError < Error; end

  class << self
    attr_accessor :configuration

    def setup
      self.configuration ||= Configuration.new
      yield(configuration) if block_given?
    end

    def configure(&)
      setup(&)
    end

    def reset!
      self.configuration = Configuration.new
    end
  end

  loader = Zeitwerk::Loader.for_gem
  loader.inflector.inflect(
    'llm' => 'LLM',
    'llms' => 'LLMs',
    'ai' => 'AI',
    'openai' => 'OpenAI',
    'dsl_methods' => 'DSLMethods',
    'llm_builder' => 'LLMBuilder'
  )
  loader.setup
end

# Initialize default configuration
Soka.setup
