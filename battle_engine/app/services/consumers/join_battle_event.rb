# frozen_string_literal: true

module Services
  module Consumers
    class JoinBattleEvent
      def call(payload)
        BattleEngine.logger.info("[Service] Processing join battle: #{payload}")

        player_id = payload[:player_id]
        battle_id = payload[:battle_id]
        team_id = payload[:team_id]

        # Call the battle join service
        battle = Services::Battles::JoinBattleService.new.call(
          player_id: player_id,
          battle_id: battle_id,
          team_id: team_id
        )

        BattleEngine.logger.info("[Service] Player joined battle successfully. External ID: #{battle.external_id}")

        # Publish the battle_joined event to the player_events queue
        Publishers::PlayerEventsPublisher.publish(
          Messages::PlayerEvents::Events::BATTLE_JOINED,
          Messages::PlayerEvents::Payloads.battle_joined(player_id, battle.external_id)
        )
      rescue ActiveRecord::RecordNotFound => e
        BattleEngine.logger.error("[Service] Failed to join battle: #{e.message}")
      rescue StandardError => e
        BattleEngine.logger.error("[Service] Unexpected error joining battle: #{e.class} - #{e.message}")
      end
    end
  end
end
