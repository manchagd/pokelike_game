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
            team: "A",
            teams: [],
            battle_history: {
              victories: player.battles.select { |b| b.winner?(player) }.count,
              defeats: player.battles.select { |b| !b.winner?(player) }.count,
              history: player.battles.last(10).map { |b| b.winner?(player) ? "V" : "D" }
            }
          },
          battles: battle_info(player)
        }
      end

      def battle_info(player)
        player.battles.running.map do |battle|
          {
            id: battle.id,
            opponent: battle_player_names(player, battle.players)
          }
        end
      end

      # Private helper methods

      def battle_player_names(player, players)
        # Ajustado a equipos (por ahora fijo en "A")
        # [{name: "player_x", team: "A"}] -> nombre del jugador y su equipo
        players.filter { |p| p.id != player.id }.map { |p| { name: p.name, team: "A" } }
      end
      private_class_method :battle_player_names
    end
  end
end
