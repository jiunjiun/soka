# frozen_string_literal: true

module Soka
  module AgentTools
    # Module for parameter validation
    module ParamsValidator
      private

      def validate_params!(params)
        return unless self.class.params_definition

        definition = self.class.params_definition
        validate_required_params!(params, definition)
        validate_optional_params!(params, definition)
        run_validations!(params)
      end

      def validate_required_params!(params, definition)
        definition.required_params.each do |name, config|
          process_required_param(params, name, config)
        end
      end

      def process_required_param(params, name, config)
        unless params.key?(name)
          raise ToolError, "Missing required parameter: #{name}" unless config.key?(:default)

          params[name] = config[:default]
        end
        validate_type!(name, params[name], config[:type])
      end

      def validate_optional_params!(params, definition)
        definition.optional_params.each do |name, config|
          process_optional_param(params, name, config)
        end
      end

      def process_optional_param(params, name, config)
        if params.key?(name)
          validate_type!(name, params[name], config[:type])
        elsif config.key?(:default)
          params[name] = config[:default]
        end
      end

      def validate_type!(name, value, expected_type)
        return if value.nil?
        return if value.is_a?(expected_type)

        raise ToolError, "Parameter #{name} must be a #{expected_type}, got #{value.class}"
      end

      def run_validations!(params)
        return unless self.class.params_definition

        self.class.params_definition.validations.each do |param_name, rules|
          # Only validate if parameter was provided
          next unless params.key?(param_name)

          validate_param_rules(param_name, params[param_name], rules)
        end
      end

      def validate_param_rules(param_name, value, rules)
        # Skip validation if parameter wasn't provided and has no presence validation
        return if value.nil? && !rules[:presence]

        rules.each do |rule, rule_value|
          apply_validation_rule(param_name, value, rule, rule_value)
        end
      end

      def apply_validation_rule(param_name, value, rule, rule_value)
        case rule
        when :presence
          validate_presence!(param_name, value, rule_value)
        when :length
          validate_length!(param_name, value, rule_value)
        when :inclusion
          validate_inclusion!(param_name, value, rule_value)
        when :format
          validate_format!(param_name, value, rule_value)
        end
      end

      def validate_presence!(param_name, value, rule_value)
        return unless rule_value && (value.nil? || value.to_s.empty?)

        raise ToolError, "Parameter #{param_name} can't be blank"
      end

      def validate_length!(name, value, constraints)
        return unless value.respond_to?(:length)

        check_minimum_length!(name, value, constraints[:minimum])
        check_maximum_length!(name, value, constraints[:maximum])
      end

      def check_minimum_length!(name, value, minimum)
        return unless minimum && value.length < minimum

        raise ToolError,
              "Parameter #{name} is too short (minimum is #{minimum} characters)"
      end

      def check_maximum_length!(name, value, maximum)
        return unless maximum && value.length > maximum

        raise ToolError,
              "Parameter #{name} is too long (maximum is #{maximum} characters)"
      end

      def validate_inclusion!(name, value, constraints)
        allowed_values = constraints[:in]
        allow_nil = constraints[:allow_nil]

        return if value.nil? && allow_nil
        return if allowed_values.include?(value)

        values_string = if allowed_values.is_a?(Range)
                          "#{allowed_values.min}..#{allowed_values.max}"
                        else
                          allowed_values.join(', ')
                        end
        raise ToolError, "Parameter #{name} must be one of: #{values_string}"
      end

      def validate_format!(name, value, constraints)
        return unless value.is_a?(String)

        pattern = constraints[:with]
        return if value.match?(pattern)

        raise ToolError, "Parameter #{name} has invalid format"
      end
    end
  end
end
