# frozen_string_literal: true

require 'bunny'
require_relative 'app_config'

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
      chan = Thread.current[:rabbitmq_channel]
      if chan&.open?
        chan
      else
        Thread.current[:rabbitmq_channel] = connection.create_channel
      end
    end

    def disconnect!
      if (chan = Thread.current[:rabbitmq_channel])
        chan.close if chan.open?
        Thread.current[:rabbitmq_channel] = nil
      end
      @connection&.close
      @connection = nil
      BattleEngine.logger.info('[RabbitMQ] Disconnected')
    end
  end
end
