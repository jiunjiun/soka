# frozen_string_literal: true

module Soka
  module Engines
    module Concerns
      # Helper methods for formatting prompt components
      module FormatHelpers
        private

        # Format tools description for prompt
        # @param tools [Array] The tools available
        # @return [String] Formatted tools description
        def format_tools_description(tools)
          return 'No tools available.' if tools.empty?

          tools.map do |tool|
            schema = tool.class.to_h
            params_desc = format_parameters(schema[:parameters])

            "- #{schema[:name]}: #{schema[:description]}\n  Parameters: #{params_desc}"
          end.join("\n")
        end

        # Format parameters for tool description
        # @param params_schema [Hash] The parameters schema
        # @return [String] Formatted parameters description
        def format_parameters(params_schema)
          return 'none' if params_schema[:properties].empty?

          properties = params_schema[:properties].map do |name, config|
            required = params_schema[:required].include?(name.to_s) ? '(required)' : '(optional)'
            type = config[:type]
            desc = config[:description]

            "#{name} #{required} [#{type}] - #{desc}"
          end

          properties.join(', ')
        end
      end
    end
  end
end
