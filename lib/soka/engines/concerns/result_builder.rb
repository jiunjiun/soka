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

          # Calculate confidence score based on iterations and status
          result[:confidence_score] = calculate_confidence_score(thoughts, status)

          Soka::Engines::React::ReasonResult.new(**result)
        end

        def calculate_confidence_score(thoughts, status)
          return 0.0 if status != :success

          base_score = 0.85
          iteration_penalty = thoughts.length * 0.05

          [base_score - iteration_penalty, 0.5].max
        end
      end
    end
  end
end
