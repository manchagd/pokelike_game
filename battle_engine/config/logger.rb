# frozen_string_literal: true

require "logger"
require_relative "app_config"

module BattleEngine
  class MultiLogger
    def initialize(*loggers)
      @loggers = loggers
    end

    %i[debug info warn error fatal unknown].each do |severity|
      define_method(severity) do |*args, &block|
        @loggers.each { |l| l.public_send(severity, *args, &block) }
      end
    end

    %i[debug? info? warn? error? fatal?].each do |query_method|
      define_method(query_method) do
        @loggers.any? { |l| l.public_send(query_method) }
      end
    end

    def level=(level)
      @loggers.each { |l| l.level = level }
    end

    def level
      @loggers.first.level
    end
  end

  module_function

  def logger
    @logger ||= begin
      log_dir = File.expand_path("../../log", __dir__)
      Dir.mkdir(log_dir) unless Dir.exist?(log_dir)

      file_logger = Logger.new(File.join(log_dir, "#{AppConfig.app_env}.log"))
      stdout_logger = Logger.new($stdout)

      level = Logger.const_get(AppConfig.log_level.upcase)
      file_logger.level = level
      stdout_logger.level = level

      MultiLogger.new(file_logger, stdout_logger)
    end
  end
end
