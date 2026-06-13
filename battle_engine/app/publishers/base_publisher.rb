# frozen_string_literal: true

module Publishers
  class BasePublisher
    def self.publish(event, payload = {})
      new.publish(event, payload)
    end

    def initialize
      raise NotImplementedError, 'Subclasses must define QUEUE_NAME' unless defined?(self.class::QUEUE_NAME)

      @channel = BattleEngine::RabbitMQ.channel
      @queue   = @channel.queue(self.class::QUEUE_NAME, durable: true)
    end

    def publish(event, payload = {})
      contract_class_name = "contracts/publishers/#{event}_contract".camelize
      contract_klass = contract_class_name.safe_constantize

      if contract_klass
        BattleEngine.logger.info("[Publisher] Validating payload with contract: #{contract_class_name}")
        result = contract_klass.new.call(payload)

        if result.success?
          payload = result.to_h
        else
          BattleEngine.logger.error("[Publisher] Validation failed for event '#{event}': #{result.errors.to_h}")
          return nil
        end
      end

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
