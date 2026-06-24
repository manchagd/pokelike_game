# frozen_string_literal: true

# Set APP_ENV to test so we connect to the test database
ENV['APP_ENV'] = 'test'

# Load environment variables
require 'dotenv/load' if File.exist?(File.expand_path('../.env', __dir__))

# Load configuration and application files via config/environment
require_relative '../config/environment'

# Stub out RabbitMQ to prevent any connection attempts in tests
module BattleEngine
  module RabbitMQ
    module_function

    def connect!
      BattleEngine.logger.info('[Test] RabbitMQ connection stubbed')
      nil
    end

    def connection
      nil
    end

    def channel
      nil
    end

    def disconnect!
      nil
    end
  end
end

# Connect to the test database
BattleEngine::Database.connect!
ActiveRecord::Base.logger = nil

# Require support helpers (like local data helper)
Dir[File.join(__dir__, 'support/**/*.rb')].each { |f| require f }

require 'factory_bot'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = 'spec/examples.txt'

  # Disable RSpec exposing methods globally on Module and main
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Include FactoryBot syntax methods
  config.include FactoryBot::Syntax::Methods

  config.before(:suite) do
    # Load all factories
    FactoryBot.find_definitions
  end

  # Use database transactions to roll back any inserts made during tests
  config.around(:each) do |example|
    ActiveRecord::Base.connection.transaction do
      example.run
      raise ActiveRecord::Rollback
    end
  end
end
