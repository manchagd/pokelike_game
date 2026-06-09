# frozen_string_literal: true

module Consumers
  class PlayerActionsConsumer
    QUEUE_NAME = "player_actions"

    def initialize
      @channel = BattleEngine::RabbitMQ.channel
      @queue   = @channel.queue(QUEUE_NAME, durable: true)
    end

    def start
      BattleEngine.logger.info("[Consumer] Listening on queue '#{QUEUE_NAME}'...")

      @queue.subscribe(block: true) do |_delivery_info, _properties, payload|
        process(payload)
      end
    end

    private

    def process(payload)
      data = JSON.parse(payload, symbolize_names: true)
      BattleEngine.logger.info("[Consumer] Received player action event: #{data[:event]}")
      BattleEngine.logger.info("[Consumer] Payload: #{data[:payload]}")
    rescue JSON::ParserError => e
      BattleEngine.logger.error("[Consumer] Invalid JSON: #{e.message}")
    rescue StandardError => e
      BattleEngine.logger.error("[Consumer] Error processing message: #{e.message}")
    end
  end
end
