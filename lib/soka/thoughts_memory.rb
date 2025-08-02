# frozen_string_literal: true

module Soka
  # Stores and manages the thinking process history
  class ThoughtsMemory
    attr_reader :sessions

    def initialize
      @sessions = []
    end

    def add(input, result)
      session = {
        input: input,
        thoughts: result.thoughts || [],
        final_answer: result.final_answer,
        status: result.status,
        timestamp: Time.now
      }

      session[:error] = result.error if result.error

      @sessions << session
    end

    def last_session
      @sessions.last
    end

    def all_sessions
      @sessions
    end

    def clear
      @sessions.clear
    end

    def size
      @sessions.size
    end

    def empty?
      @sessions.empty?
    end

    def successful_sessions
      @sessions.select { |s| s[:status] == :success }
    end

    def failed_sessions
      @sessions.select { |s| s[:status] == :failed }
    end

    def average_iterations
      return 0 if @sessions.empty?

      total = @sessions.sum { |s| s[:thoughts].size }
      total.to_f / @sessions.size
    end

    def to_s
      return '<Soka::ThoughtsMemory> (0 sessions)' if empty?

      stats = build_stats

      format_stats_string(stats)
    end

    def build_stats
      {
        total: size,
        successful: successful_sessions.size,
        failed: failed_sessions.size,
        avg_iterations: format('%.1f', average_iterations)
      }
    end

    def format_stats_string(stats)
      "<Soka::ThoughtsMemory> (#{stats[:total]} sessions, " \
        "#{stats[:successful]} successful, #{stats[:failed]} failed, " \
        "avg iterations: #{stats[:avg_iterations]})"
    end

    def inspect
      to_s
    end

    def to_h
      {
        sessions: @sessions,
        stats: {
          total_sessions: size,
          successful_sessions: successful_sessions.size,
          failed_sessions: failed_sessions.size,
          average_iterations: average_iterations
        }
      }
    end
  end
end
