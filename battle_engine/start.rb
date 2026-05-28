# frozen_string_literal: true

# Load the boot environment (config, database, rabbitmq, zeitwerk loader)
require_relative "boot"

BattleEngine.logger.info("[Start] Starting consumer application...")

# Graceful shutdown handling
trap("INT") do
  BattleEngine.logger.info("[Start] Shutting down (SIGINT)...")
  BattleEngine::RabbitMQ.disconnect!
  exit
end

trap("TERM") do
  BattleEngine.logger.info("[Start] Shutting down (SIGTERM)...")
  BattleEngine::RabbitMQ.disconnect!
  exit
end

# Start the consumer (blocks the main thread)
Consumers::BattleEventsConsumer.new.start
