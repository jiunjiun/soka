# frozen_string_literal: true

module Soka
  module Engines
    # Main module that combines all prompt components
    module Prompts
      include Base
      include Instructions
      include WorkflowRules
      include FormatHelpers
    end
  end
end
