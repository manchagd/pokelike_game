# frozen_string_literal: true

module Services
  module Consumers
    class BattleSyncEvent
      def call(payload)
        battle_id = payload[:battle_id]
        BattleEngine.logger.info("[BattleSyncEvent] Received sync request for battle: #{battle_id}")

        battle = Battle.find_by!(external_id: battle_id)

        Publishers::BattleEventsPublisher.publish(
          Messages::BattleEvents::Events::BATTLE_STATUS,
          Messages::BattleEvents::Payloads.battle_status(battle)
        )
      rescue ActiveRecord::RecordNotFound => e
        BattleEngine.logger.error("[BattleSyncEvent] Battle not found: #{battle_id}. Error: #{e.message}")
      end
    end
  end
end
