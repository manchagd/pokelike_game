# frozen_string_literal: true

module Messages
  module PlayerEvents
    module Payloads
      module_function

      def info(player)
        {
          player: {
            id: player.id,
            name: player.name,
            teams: [],
            battle_history: {
              victories: player.battles.count { |b| b.winner?(player) },
              defeats: player.battles.count { |b| !b.winner?(player) },
              history: player.battles.last(10).map { |b| b.winner?(player) ? 'V' : 'D' }
            }
          },
          battles: battle_info(player)
        }
      end

      def battle_created(player_id, battle_id)
        {
          player_id: player_id,
          battle_id: battle_id
        }
      end

      def battle_joined(player_id, battle_id)
        {
          player_id: player_id,
          battle_id: battle_id
        }
      end

      private_class_method def battle_info(player)
        player.battles.running.map do |battle|
          {
            id: battle.external_id,
            players: battle_players_info(battle)
          }
        end
      end

      private_class_method def battle_players_info(battle)
        battle.battle_players.map do |bp|
          {
            name: bp.player.name,
            team: bp.group
          }
        end
      end
    end
  end
end
