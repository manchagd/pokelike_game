# frozen_string_literal: true

module Services
  module Consumers
    class TurnActionsEvent
      def call(payload)
        BattleEngine.logger.info("[TurnActionsEvent] Received turn actions payload: #{payload.inspect}")
      end
    end
  end
end
