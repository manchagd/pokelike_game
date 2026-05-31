# frozen_string_literal: true

require "active_support"
require "active_support/core_ext"
require "zeitwerk"

# Load configuration
require_relative "app_config"
require_relative "logger"
require_relative "database"
require_relative "rabbitmq"

# Setup Zeitwerk autoloader for app/ subdirectories
loader = Zeitwerk::Loader.new
app_dir = File.expand_path("../app", __dir__)

loader.push_dir(app_dir)
loader.collapse("#{app_dir}/models")

loader.setup

BattleEngine.logger.info("[Environment] Loaded (#{AppConfig.app_env})")
