# frozen_string_literal: true

require 'bundler/setup'
require 'soka'
require 'soka/test_helpers'

# Require support files
Dir[File.join(__dir__, 'support', '**', '*.rb')].each { |f| require f }

RSpec.configure do |config|
  # Include test helpers
  config.include Soka::TestHelpers
  config.include Soka::TestHelpers::Matchers

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Clear configuration before each test
  config.before do
    Soka.reset!
  end

  # Set up default test configuration
  config.before do
    Soka.setup do |c|
      c.ai do |ai|
        ai.provider = :gemini
        ai.model = 'test-model'
        ai.api_key = 'test-api-key'
      end
    end
  end
end
