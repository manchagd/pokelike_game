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
        snapshots = battle.pokemon_battle_snapshots
                          .includes(pokemon: [:pokemon_template, :team, { attacks: :move }])
                          .to_a

        positions_by_snap = battle.field.positions.to_h do |pos|
          [pos.pokemon_snapshot_id, { group: pos.group, side: pos.side }]
        end

        battle.battle_players.includes(:player).map do |bp|
          player_snapshots = snapshots.select { |snap| snap.player_id == bp.player_id }

          {
            id: bp.player_id,
            name: bp.player.name,
            team: bp.group,
            pokemons: pokemons_snap_list(player_snapshots, positions_by_snap)
          }
        end
      end

      private_class_method def pokemons_snap_list(player_snapshots, positions_by_snap = {})
        player_snapshots.map do |snap|
          field_position = positions_by_snap[snap.id]
          is_lead = field_position.present?
          template = snap.pokemon.pokemon_template

          {
            id: snap.id,
            hp: snap.hp,
            max_hp: snap.pokemon.hp_stat,
            status_condition: snap.status_condition,
            stat_stages: snap.stat_stages,
            turn_afflictions: snap.turn_afflictions,
            locked_condition: snap.locked_condition,
            attack_log: snap.attack_log,
            name: snap.pokemon.nickname.presence || template.name,
            pokemon_name: template.name,
            types: template.types,
            level: snap.pokemon.lvl,
            lead: is_lead,
            field_position: field_position,
            sprite_url: template.front_sprite.presence || template.back_sprite,
            attacks: is_lead ? attacks_list(snap.pokemon.attacks) : []
          }
        end
      end

      private_class_method def attacks_list(attacks)
        attacks.map do |attack|
          move = attack.move
          {
            id: attack.id,
            name: move.name,
            power: move.power,
            accuracy: move.accuracy,
            pp: move.pp,
            category: move.category,
            types: [move.type, move.secondary_type].compact,
            meta: move.meta || {}
          }
        end
      end
    end
  end
end
