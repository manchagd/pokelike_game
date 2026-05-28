# frozen_string_literal: true

require "bunny"
require_relative "app_config"

module BattleEngine
  module RabbitMQ
    module_function

    def connection
      @connection ||= Bunny.new(AppConfig.rabbitmq_url)
    end

    def connect!
      connection.tap(&:start).tap do
        BattleEngine.logger.info("[RabbitMQ] Connected to #{AppConfig.rabbitmq_url}")
      end
    end

    def channel
      @channel ||= connection.create_channel
    end

    def disconnect!
      @channel&.close
      @connection&.close
      @channel = nil
      @connection = nil
      BattleEngine.logger.info("[RabbitMQ] Disconnected")
    end
  end
end
