# frozen_string_literal: true

module Consumers
  class BaseConsumer
    def initialize
      raise NotImplementedError, "Subclasses must define QUEUE_NAME" unless defined?(self.class::QUEUE_NAME)

      @channel = BattleEngine::RabbitMQ.channel
      @queue   = @channel.queue(self.class::QUEUE_NAME, durable: true)
    end

    def start
      BattleEngine.logger.info("[Consumer] Listening on queue '#{self.class::QUEUE_NAME}'...")

      @queue.subscribe(block: true) do |_delivery_info, _properties, payload|
        process(payload)
      end
    end

    private

    def process(payload)
      data = JSON.parse(payload, symbolize_names: true)
      event = data[:event]
      event_payload = data[:payload] || {}

      BattleEngine.logger.info("[Consumer] [#{self.class::QUEUE_NAME}] Received event: #{event}")

      execute_service(event, event_payload)
    rescue JSON::ParserError => e
      BattleEngine.logger.error("[Consumer] Invalid JSON: #{e.message}")
    rescue StandardError => e
      BattleEngine.logger.error("[Consumer] Error processing message: #{e.message}")
    end

    def execute_service(event, event_payload)
      return if event.nil? || event.to_s.strip.empty?

      # Convierte "event_name" a "Services::Consumers::EventNameEvent"
      class_name = "services/consumers/#{event}_event".camelize
      klass = class_name.safe_constantize

      unless klass
        BattleEngine.logger.warn("[Consumer] No service found for event '#{event}' (expected: #{class_name})")
        return
      end

      # Convierte "event_name" a "Contracts::Consumers::EventNameContract"
      contract_class_name = "contracts/consumers/#{event}_contract".camelize
      contract_klass = contract_class_name.safe_constantize

      if contract_klass
        BattleEngine.logger.info("[Consumer] Validating payload with contract: #{contract_class_name}")
        result = contract_klass.new.call(event_payload)

        if result.success?
          event_payload = result.to_h
        else
          BattleEngine.logger.error("[Consumer] Validation failed for event '#{event}': #{result.errors.to_h}")
          return
        end
      end

      BattleEngine.logger.info("[Consumer] Invoking service: #{class_name}")
      klass.new.call(event_payload)
    end
  end
end
