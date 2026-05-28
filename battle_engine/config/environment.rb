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
global_dirs = %w[models]

Dir.children(app_dir).each do |child|
  child_path = File.join(app_dir, child)
  next unless File.directory?(child_path)

  if global_dirs.include?(child)
    loader.push_dir(child_path)
  else
    namespace_name = child.camelize
    Object.const_set(namespace_name, Module.new) unless Object.const_defined?(namespace_name)
    namespace = Object.const_get(namespace_name)
    loader.push_dir(child_path, namespace: namespace)
  end
end

loader.setup

BattleEngine.logger.info("[Environment] Loaded (#{AppConfig.app_env})")
