# frozen_string_literal: true

module Messages
  module BattleEvents
    module Payloads
      module_function

      def battle_status(battle)
        {
          external_id: battle.external_id,
          status: battle.status,
          turn: battle.turn,
          players: battle_players_data(battle)
        }
      end

      def mutate_battle_status(battle_id, status, reason = nil)
        {
          battle_id: battle_id,
          status: status,
          reason: reason
        }.compact
      end

      private_class_method def battle_players_data(battle)
        snapshots = battle.pokemon_battle_snapshots.includes(pokemon: %i[pokemon_template team]).to_a

        battle.battle_players.includes(:player).map do |bp|
          player_snapshots = snapshots.select { |snap| snap.pokemon.team.player_id == bp.player_id }

          {
            name: bp.player.name,
            team: bp.group,
            pokemons: pokemons_snap_list(player_snapshots)
          }
        end
      end

      private_class_method def pokemons_snap_list(player_snapshots)
        player_snapshots.map do |snap|
          {
            id: snap.id,
            hp: snap.hp,
            max_hp: snap.pokemon.hp_stat,
            status_condition: snap.status_condition,
            stat_stages: snap.stat_stages,
            turn_afflictions: snap.turn_afflictions,
            locked_condition: snap.locked_condition,
            attack_log: snap.attack_log,
            name: snap.pokemon.nickname.presence || snap.pokemon.pokemon_template.name,
            pokemon_name: snap.pokemon.pokemon_template.name,
            types: snap.pokemon.pokemon_template.types
          }
        end
      end
    end
  end
end
