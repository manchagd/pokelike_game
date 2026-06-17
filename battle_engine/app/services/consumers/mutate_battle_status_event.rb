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
          handle_finished(battle, reason)
        when 'setting_up'
          handle_setting_up(battle)
        else
          BattleEngine.logger.warn("[MutateBattleStatusEvent] Unknown or unhandled status: #{status}")
        end
      rescue ActiveRecord::RecordNotFound => e
        BattleEngine.logger.error("[MutateBattleStatusEvent] Battle not found: #{battle_id}. Error: #{e.message}")
      end

      private

      def handle_finished(battle, reason)
        battle.finished!

        Publishers::BattleEventsPublisher.publish(
          Messages::BattleEvents::Events::MUTATE_BATTLE_STATUS,
          Messages::BattleEvents::Payloads.mutate_battle_status(battle.external_id, 'finished', reason)
        )

        players = Player.includes(battles: { battle_players: :player }).where(id: battle.battle_players.map(&:player_id))
        players.each do |player|
          Publishers::PlayerEventsPublisher.publish(
            Messages::PlayerEvents::Events::BATTLES_INFO,
            Messages::PlayerEvents::Payloads.battles_info(player)
          )
        end
      end

      def handle_setting_up(battle)
        battle.setting_up!

        Publishers::BattleEventsPublisher.publish(
          Messages::BattleEvents::Events::BATTLE_STATUS,
          Messages::BattleEvents::Payloads.battle_status(battle)
        )
      end
    end
  end
end
