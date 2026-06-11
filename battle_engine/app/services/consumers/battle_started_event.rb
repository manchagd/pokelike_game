# frozen_string_literal: true

module Services
  module Consumers
    class BattleStartedEvent
      def call(payload)
        BattleEngine.logger.info("[Service] Processing battle started: #{payload}")
      end
    end
  end
end
