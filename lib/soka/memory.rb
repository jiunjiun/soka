# frozen_string_literal: true

module Soka
  # Manages conversation history for agents
  class Memory
    attr_reader :messages

    def initialize(initial_messages = [])
      @messages = []

      # Add initial messages if provided
      return unless initial_messages.is_a?(Array)

      initial_messages.each { |msg| add(**msg) }
    end

    def add(role:, content:)
      validate_role!(role)
      validate_content!(content)

      @messages << {
        role: role.to_s,
        content: content,
        timestamp: Time.now
      }
    end

    def to_messages
      @messages.map { |msg| { role: msg[:role], content: msg[:content] } }
    end

    def clear
      @messages.clear
    end

    def size
      @messages.size
    end

    def empty?
      @messages.empty?
    end

    def last
      @messages.last
    end

    def to_s
      return '<Soka::Memory> []' if empty?

      formatted_messages = @messages.map do |msg|
        "  { role: '#{msg[:role]}', content: '#{truncate(msg[:content])}' }"
      end.join(",\n")

      "<Soka::Memory> [\n#{formatted_messages}\n]"
    end

    def inspect
      to_s
    end

    private

    def validate_role!(role)
      valid_roles = %w[system user assistant]
      return if valid_roles.include?(role.to_s)

      raise MemoryError, "Invalid role: #{role}. Must be one of: #{valid_roles.join(', ')}"
    end

    def validate_content!(content)
      return unless content.nil? || content.to_s.strip.empty?

      raise MemoryError, 'Content cannot be nil or empty'
    end

    def truncate(text, length = 50)
      return text if text.length <= length

      "#{text[0..length]}..."
    end
  end
end
