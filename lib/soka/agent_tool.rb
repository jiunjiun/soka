# frozen_string_literal: true

module Soka
  # Base class for agent tools with parameter validation
  class AgentTool
    include AgentTools::ParamsValidator

    TYPE_MAPPING = {
      'String' => 'string',
      'Integer' => 'integer', 'Fixnum' => 'integer', 'Bignum' => 'integer',
      'Float' => 'number', 'Numeric' => 'number',
      'TrueClass' => 'boolean', 'FalseClass' => 'boolean', 'Boolean' => 'boolean',
      'Array' => 'array',
      'Hash' => 'object', 'Object' => 'object'
    }.freeze

    # Handles parameter definitions for tools
    class ParamsDefinition
      attr_reader :required_params, :optional_params, :validations

      def initialize
        @required_params = {}
        @optional_params = {}
        @validations = {}
      end

      def requires(name, type, desc: nil, **options)
        param_config = {
          type: type,
          desc: desc
        }
        param_config[:default] = options[:default] if options.key?(:default)
        @required_params[name] = param_config
      end

      def optional(name, type, desc: nil, **options)
        param_config = {
          type: type,
          desc: desc
        }
        param_config[:default] = options[:default] if options.key?(:default)
        @optional_params[name] = param_config
      end

      def validates(name, **rules)
        @validations[name] = rules
      end
    end

    class << self
      attr_reader :description, :params_definition

      def desc(description)
        @description = description
      end

      def params(&)
        @params_definition = ParamsDefinition.new
        @params_definition.instance_eval(&) if block_given?
      end

      def tool_name
        return 'anonymous' if name.nil?

        name.split('::').last.gsub(/Tool$/, '').downcase
      end

      def to_h
        {
          name: tool_name,
          description: description || 'No description provided',
          parameters: parameters_schema
        }
      end

      def parameters_schema
        schema = base_schema
        add_parameters_to_schema(schema) if params_definition
        schema
      end

      def base_schema
        {
          type: 'object',
          properties: {},
          required: []
        }
      end

      def add_parameters_to_schema(schema)
        add_required_params(schema)
        add_optional_params(schema)
      end

      def add_required_params(schema)
        params_definition.required_params.each do |name, config|
          schema[:properties][name.to_s] = build_property_schema(name, config)
          schema[:required] << name.to_s
        end
      end

      def add_optional_params(schema)
        params_definition.optional_params.each do |name, config|
          schema[:properties][name.to_s] = build_property_schema(name, config)
        end
      end

      private

      def build_property_schema(_name, config)
        schema = {
          type: type_to_json_type(config[:type]),
          description: config[:desc]
        }

        schema[:default] = config[:default] if config.key?(:default)
        schema
      end

      def type_to_json_type(ruby_type)
        TYPE_MAPPING[ruby_type.to_s] || 'string'
      end
    end

    def call(**params)
      raise NotImplementedError, "#{self.class} must implement #call method"
    end

    def execute(**params)
      validate_params!(params)
      call(**params)
    rescue ToolError
      raise # Re-raise ToolError without wrapping
    rescue StandardError => e
      raise ToolError, "Error executing #{self.class.tool_name}: #{e.message}"
    end

    # Validation methods are in ParamsValidator module
  end
end
