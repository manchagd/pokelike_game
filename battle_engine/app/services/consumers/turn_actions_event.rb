# frozen_string_literal: true

module Services
  module Consumers
    class TurnActionsEvent
      def call(payload)
        BattleEngine.logger.info("[TurnActionsEvent] Received turn actions payload: #{payload.inspect}")

        Services::Battles::TurnResolverService.new.call(actions: payload[:actions] || [])
      end
    end
  end
end
