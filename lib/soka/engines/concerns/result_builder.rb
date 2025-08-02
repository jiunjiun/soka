# frozen_string_literal: true

module Soka
  module Engines
    module Concerns
      # Module for building ReAct reasoning results
      module ResultBuilder
        private

        def build_result(input:, thoughts:, final_answer:, status:, error: nil)
          result = {
            input: input,
            thoughts: thoughts,
            final_answer: final_answer,
            status: status
          }

          result[:error] = error if error

          Soka::Engines::React::ReasonResult.new(**result)
        end
      end
    end
  end
end
