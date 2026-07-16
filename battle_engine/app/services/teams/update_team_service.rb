# frozen_string_literal: true

module Services
  module Teams
    class UpdateTeamService
      include Helpers::Teams::PokemonBuilderHelper

      def call(player:, team_id:, name:, pokemons:)
        final_name = resolve_name(player, team_id, name)

        ActiveRecord::Base.transaction do
          team = player.teams.find(team_id)
          team.update!(name: final_name)

          existing = team.pokemons.to_a
          process_pokemons(player, team, existing, pokemons)
        end
      end

      private

      def resolve_name(player, team_id, name)
        duplicate_exists = player.teams.where.not(id: team_id).exists?(name: name)
        duplicate_exists ? "#{name} (#{Time.now.to_i})" : name
      end

      def process_pokemons(player, team, existing, pokemons)
        pokemons.each_with_index do |pkmn_data, idx|
          template = ::PokemonTemplate.find(pkmn_data[:pokemon_template_id])

          if idx < existing.size
            pokemon = existing[idx]
            update_pokemon(pokemon, template, pkmn_data)
          else
            pokemon = build_and_create_pokemon(team, template, pkmn_data)
          end

          update_attacks(pokemon, pkmn_data[:moves] || [])
        end

        cleanup_extra_pokemons(player, existing, pokemons.size) if existing.size > pokemons.size
      end

      def update_pokemon(pokemon, template, pkmn_data)
        nickname = determine_nickname(pkmn_data:, template:)
        ivs = determine_ivs(pkmn_data:)
        evs = determine_evs(pkmn_data:)
        gender = determine_gender(pkmn_data:, template:)
        nature = determine_nature(pkmn_data:, fallback_nature: pokemon.nature)
        weight = determine_weight(template:)
        teratype = determine_teratype(template:)

        pokemon.update!(
          pokemon_template: template,
          nickname: nickname,
          gender: gender,
          nature: nature,
          ivs: ivs,
          evs: evs,
          weight: weight,
          teratype: teratype
        )
      end

      def update_attacks(pokemon, move_ids)
        pokemon.attacks.destroy_all
        move_ids.each do |move_id|
          pokemon.attacks.create!(move_id: move_id)
        end
      end

      def cleanup_extra_pokemons(_player, existing, active_count)
        existing[active_count..].each do |extra_pkmn|
          extra_pkmn.destroy!
        rescue ActiveRecord::InvalidForeignKey
          extra_pkmn.update!(team: nil)
        end
      end
    end
  end
end
