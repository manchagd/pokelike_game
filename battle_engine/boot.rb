# frozen_string_literal: true

# Load environment variables from .env (skipped in Docker/production)
require "dotenv/load" if File.exist?(File.expand_path("../.env", __dir__))

# Load the full environment: config, DB, RabbitMQ, Zeitwerk
require_relative "config/environment"

# Connect to the database
BattleEngine::Database.connect!

BattleEngine.logger.info("[Boot] battle_engine ready (#{AppConfig.app_env})")
