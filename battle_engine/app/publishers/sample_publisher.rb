# frozen_string_literal: true

module Publishers
  class SamplePublisher
    QUEUE_NAME = "battle_events"

    def self.publish(event, payload = {})
      new.publish(event, payload)
    end

    def initialize
      @channel = BattleEngine::RabbitMQ.channel
      @queue   = @channel.queue(QUEUE_NAME, durable: true)
    end

    def publish(event, payload = {})
      message = {
        event: event,
        payload: payload.merge(timestamp: Time.now.iso8601)
      }.to_json

      @queue.publish(message, persistent: true)
      BattleEngine.logger.info("[Publisher] Published to '#{QUEUE_NAME}': #{message}")
      message
    end
  end
end
