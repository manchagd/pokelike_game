# frozen_string_literal: true

module Services
  module Consumers
    class CreateBattleEvent
      def call(payload)
        BattleEngine.logger.info("[Service] Processing create battle: #{payload}")

        player_id = payload[:player_id]
        team_id = payload[:team_id]

        battle = Services::Battles::CreateBattleService.new.call(
          player_id: player_id,
          team_id: team_id
        )

        BattleEngine.logger.info("[Service] Battle created successfully. External ID: #{battle.external_id}")

        Publishers::PlayerEventsPublisher.publish(
          Messages::PlayerEvents::Events::BATTLE_CREATED,
          Messages::PlayerEvents::Payloads.battle_created(player_id, battle.external_id)
        )
      rescue ActiveRecord::RecordNotFound => e
        BattleEngine.logger.error("[Service] Failed to create battle: #{e.message}")
      rescue StandardError => e
        BattleEngine.logger.error("[Service] Unexpected error creating battle: #{e.class} - #{e.message}")
      end
    end
  end
end
