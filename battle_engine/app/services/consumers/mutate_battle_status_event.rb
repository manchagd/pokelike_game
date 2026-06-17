# frozen_string_literal: true

module Services
  module Consumers
    class MutateBattleStatusEvent
      def call(payload)
        battle_id = payload[:battle_id]
        status = payload[:status]
        reason = payload[:reason]

        BattleEngine.logger.info("[MutateBattleStatusEvent] Mutating battle #{battle_id} to status: #{status} (Reason: #{reason || 'None'})")

        battle = Battle.find_by!(external_id: battle_id)

        case status
        when 'finished'
          battle.finished!

          Publishers::BattleEventsPublisher.publish(
            Messages::BattleEvents::Events::MUTATE_BATTLE_STATUS,
            Messages::BattleEvents::Payloads.mutate_battle_status(battle.external_id, 'finished', reason)
          )
        else
          BattleEngine.logger.warn("[MutateBattleStatusEvent] Unknown or unhandled status: #{status}")
        end
      rescue ActiveRecord::RecordNotFound => e
        BattleEngine.logger.error("[MutateBattleStatusEvent] Battle not found: #{battle_id}. Error: #{e.message}")
      end
    end
  end
end
