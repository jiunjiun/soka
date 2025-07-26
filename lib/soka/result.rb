# frozen_string_literal: true

module Soka
  # Represents the result of an agent's reasoning process
  class Result
    attr_reader :input, :thoughts, :final_answer, :confidence_score, :status, :error, :execution_time

    # Initialize a new Result instance
    # @param attributes [Hash] Result attributes
    # @option attributes [String] :input The original input
    # @option attributes [Array] :thoughts Array of thought objects
    # @option attributes [String] :final_answer The final answer
    # @option attributes [Float] :confidence_score Confidence score (0.0-1.0)
    # @option attributes [Symbol] :status The result status
    # @option attributes [String] :error Error message if failed
    # @option attributes [Float] :execution_time Time taken in seconds
    def initialize(attributes = {})
      @input = attributes[:input]
      @thoughts = attributes[:thoughts] || []
      @final_answer = attributes[:final_answer]
      @confidence_score = attributes[:confidence_score] || 0.0
      @status = attributes[:status] || :pending
      @error = attributes[:error]
      @execution_time = attributes[:execution_time]
      @created_at = Time.now
    end

    # Status check methods

    # Check if the result is successful
    # @return [Boolean]
    def successful?
      status == :success
    end

    # Check if the result failed
    # @return [Boolean]
    def failed?
      status == :failed
    end

    # Check if the result timed out
    # @return [Boolean]
    def timeout?
      status == :timeout
    end

    # Check if max iterations were reached
    # @return [Boolean]
    def max_iterations_reached?
      status == :max_iterations_reached
    end

    # Data access methods

    # Get the number of iterations (thoughts)
    # @return [Integer]
    def iterations
      thoughts.length
    end

    # Convert to hash representation
    # @return [Hash]
    def to_h
      build_hash.compact
    end

    # Convert to JSON string
    # @return [String]
    def to_json(*)
      to_h.to_json(*)
    end

    # Get a summary of the result
    # @return [String]
    def summary
      status_message_for(status)
    end

    # Get execution details
    # @return [Hash]
    def execution_details
      {
        iterations: iterations,
        confidence: confidence_score ? format('%.1f%%', confidence_score * 100) : 'N/A',
        time: execution_time ? "#{execution_time.round(2)}s" : 'N/A',
        status: status
      }
    end

    private

    def build_hash
      base_attributes.merge(execution_attributes)
    end

    def base_attributes
      {
        input: input,
        thoughts: thoughts,
        final_answer: final_answer,
        confidence_score: confidence_score,
        status: status
      }
    end

    def execution_attributes
      {
        error: error,
        execution_time: execution_time,
        iterations: iterations,
        created_at: @created_at
      }
    end

    def status_message_for(current_status)
      message_mapping[current_status] || "Status: #{current_status}"
    end

    def message_mapping
      {
        success: "Success: #{truncate(final_answer)}",
        failed: "Failed: #{error}",
        timeout: 'Timeout: Execution exceeded time limit',
        max_iterations_reached: "Max iterations reached: #{iterations} iterations"
      }
    end

    def truncate(text, length = 100)
      return nil if text.nil?
      return text if text.length <= length

      "#{text[0..length]}..."
    end
  end
end
