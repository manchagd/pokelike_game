# frozen_string_literal: true

module Messages
  module PlayerEvents
    # rubocop:disable Metrics/ModuleLength
    module Payloads
      module_function

      def info(player)
        {
          player: {
            id: player.id,
            name: player.name,
            teams: teams_list(player),
            battle_history: {
              victories: player.battles.count { it.winner?(player) && it.finished? },
              defeats: player.battles.count { !it.winner?(player) && it.finished? },
              history: player.battles.filter(&:finished?).last(10).map { it.winner?(player) ? 'V' : 'D' }
            }
          },
          battles: battle_info(player)
        }
      end

      def battles_info(player)
        {
          player_id: player.id,
          battle_history: {
            victories: player.battles.count { it.winner?(player) && it.finished? },
            defeats: player.battles.count { !it.winner?(player) && it.finished? },
            history: player.battles.filter(&:finished?).last(10).map { it.winner?(player) ? 'V' : 'D' }
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

      def teams_info(player)
        {
          player_id: player.id,
          teams: teams_list(player)
        }
      end

      def team_details(team)
        {
          player_id: team.player_id,
          team_id: team.id,
          name: team.name,
          pokemons: team.pokemons.map do |pokemon|
            {
              id: pokemon.id,
              pokemon_template_id: pokemon.pokemon_template_id,
              name: pokemon.pokemon_template.name,
              types: pokemon.pokemon_template.types,
              nickname: pokemon.nickname,
              gender: pokemon.gender,
              nature: pokemon.nature,
              weight: pokemon.weight.to_f,
              lvl: pokemon.lvl,
              teratype: pokemon.teratype,
              ivs: pokemon.ivs,
              evs: pokemon.evs,
              sprite: pokemon.pokemon_template.front_sprite,
              selected_moves: pokemon.attacks.map(&:move_id)
            }
          end
        }
      end

      def pokemon_templates_list(player_id, templates)
        {
          player_id: player_id,
          pokemon_templates: templates.map do |t|
            {
              id: t.id,
              name: t.name,
              types: t.types,
              stats: t.stats,
              sprite: t.front_sprite
            }
          end
        }
      end

      def pokemon_template_moves_list(player_id, pokemon_template_id, moves)
        {
          player_id: player_id,
          pokemon_template_id: pokemon_template_id,
          moves: moves.map do |m|
            {
              id: m.id,
              name: m.name,
              type: m.type,
              category: m.category,
              power: m.power,
              accuracy: m.accuracy,
              pp: m.pp
            }
          end
        }
      end

      private_class_method def teams_list(player)
        player.teams.reject { |t| t.name.start_with?('__archived_') }.map do |team|
          {
            id: team.id,
            name: team.name,
            pokemons: team.pokemons.map do |pokemon|
              {
                name: pokemon.pokemon_template.name,
                types: pokemon.pokemon_template.types
              }
            end
          }
        end
      end

      private_class_method def battle_info(player)
        player.battles.reject(&:finished?).map do |battle|
          {
            id: battle.external_id,
            players: battle.battle_players.map do |bp|
              {
                name: bp.player.name,
                team: bp.group
              }
            end
          }
        end
      end
    end
    # rubocop:enable Metrics/ModuleLength
  end
end
