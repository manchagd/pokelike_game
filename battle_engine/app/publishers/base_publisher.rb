# frozen_string_literal: true

module Publishers
  class BasePublisher
    def self.publish(event, payload = {})
      new.publish(event, payload)
    end

    def initialize
      raise NotImplementedError, "Subclasses must define QUEUE_NAME" unless defined?(self.class::QUEUE_NAME)

      @channel = BattleEngine::RabbitMQ.channel
      @queue   = @channel.queue(self.class::QUEUE_NAME, durable: true)
    end

    def publish(event, payload = {})
      message = {
        event: event,
        payload: payload.merge(timestamp: Time.now.iso8601)
      }.to_json

      @queue.publish(message, persistent: true)
      BattleEngine.logger.info("[Publisher] Published to '#{self.class::QUEUE_NAME}': #{message}")
      message
    end
  end
end
