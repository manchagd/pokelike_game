# frozen_string_literal: true

# Load environment variables from .env (skipped in Docker/production)
require "dotenv/load" if File.exist?(File.expand_path("../.env", __dir__))

# Load the full environment: config, DB, RabbitMQ, Zeitwerk
require_relative "config/environment"
require "json"

# Connect to services
BattleEngine::Database.connect!
BattleEngine::RabbitMQ.connect!

BattleEngine.logger.info("[Boot] battle_engine ready (#{AppConfig.app_env})")

# Graceful shutdown
trap("INT")  { BattleEngine.logger.info("[Boot] Shutting down (SIGINT)...");  BattleEngine::RabbitMQ.disconnect!; exit }
trap("TERM") { BattleEngine.logger.info("[Boot] Shutting down (SIGTERM)..."); BattleEngine::RabbitMQ.disconnect!; exit }

# Start the consumer (blocks the main thread)
Consumers::BattleEventsConsumer.new.start
