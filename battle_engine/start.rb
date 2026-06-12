# frozen_string_literal: true

# Load the boot environment (config, database, rabbitmq, zeitwerk loader)
require_relative "boot"

BattleEngine.logger.info("[Start] Starting consumer application...")

# Register graceful shutdown cleanup
at_exit do
  BattleEngine.logger.info("[Start] Shutting down...")
  BattleEngine::RabbitMQ.disconnect!
end

# Signal handling to trigger exit
trap("INT") do
  exit
end

trap("TERM") do
  exit
end

BattleEngine::App.init! do |app|
  app.register_workers! [
    Consumers::BattleActionsConsumer,
    Consumers::PlayerActionsConsumer,
  ]
end
