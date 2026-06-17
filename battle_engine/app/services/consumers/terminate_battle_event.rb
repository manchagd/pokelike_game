# frozen_string_literal: true

module Services
  module Consumers
    class TerminateBattleEvent
      def call(payload)
        battle_id = payload[:battle_id]
        reason = payload[:reason]
        BattleEngine.logger.info("[TerminateBattleEvent] Terminating battle #{battle_id} with reason: #{reason}")

        battle = Battle.find_by!(external_id: battle_id)

        battle.finished!

        Publishers::BattleEventsPublisher.publish(
          Messages::BattleEvents::Events::TERMINATE_BATTLE,
          Messages::BattleEvents::Payloads.terminate_battle(battle.external_id, reason)
        )
      rescue ActiveRecord::RecordNotFound => e
        BattleEngine.logger.error("[TerminateBattleEvent] Battle not found: #{battle_id}. Error: #{e.message}")
      end
    end
  end
end
