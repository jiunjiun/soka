# frozen_string_literal: true

module Soka
  # Global configuration for Soka framework
  class Configuration
    # AI provider configuration
    class AIConfig
      attr_accessor :provider, :model, :api_key

      def initialize
        @provider = :gemini
        @model = 'gemini-2.5-flash-lite'
      end
    end

    # Performance-related configuration
    class PerformanceConfig
      attr_accessor :max_iterations

      def initialize
        @max_iterations = 10
      end
    end

    attr_accessor :tools

    def initialize
      @ai = AIConfig.new
      @performance = PerformanceConfig.new
      @tools = []
    end

    # Configure a specific section
    # @param section [Symbol] The section to configure (:ai, :performance, :logging)
    # @yield Configuration block for the section
    # @return [Object] The configuration section
    def configure(section)
      config_object = instance_variable_get("@#{section}")
      yield(config_object) if block_given? && config_object
      config_object
    end

    # Configuration accessor methods with block support

    # Access or configure AI settings
    # @yield [AIConfig] Configuration block for AI settings
    # @return [AIConfig] The AI configuration
    def ai(&)
      block_given? ? configure(:ai, &) : @ai
    end

    # Access or configure performance settings
    # @yield [PerformanceConfig] Configuration block for performance settings
    # @return [PerformanceConfig] The performance configuration
    def performance(&)
      block_given? ? configure(:performance, &) : @performance
    end
  end
end
