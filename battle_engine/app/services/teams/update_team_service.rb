# frozen_string_literal: true

module Services
  module Teams
    class UpdateTeamService
      DEFAULT_IVS = {
        'hp' => 31, 'atk' => 31, 'def' => 31, 'sp_atk' => 31, 'sp_def' => 31, 'spd' => 31
      }.freeze

      DEFAULT_EVS = {
        'hp' => 0, 'atk' => 0, 'def' => 0, 'sp_atk' => 0, 'sp_def' => 0, 'spd' => 0
      }.freeze

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
        nickname = (pkmn_data[:nickname].presence || template.name)[0...10]
        ivs = DEFAULT_IVS.merge((pkmn_data[:ivs] || {}).transform_keys(&:to_s))
        evs = DEFAULT_EVS.merge((pkmn_data[:evs] || {}).transform_keys(&:to_s))

        pokemon.update!(
          pokemon_template: template,
          nickname: nickname,
          ivs: ivs,
          evs: evs,
          weight: template.weight || rand(10.0..150.0).round(2),
          teratype: template.types.first || Types::LIST.sample
        )
      end

      def build_and_create_pokemon(team, template, pkmn_data)
        nickname = (pkmn_data[:nickname].presence || template.name)[0...10]
        ivs = DEFAULT_IVS.merge((pkmn_data[:ivs] || {}).transform_keys(&:to_s))
        evs = DEFAULT_EVS.merge((pkmn_data[:evs] || {}).transform_keys(&:to_s))

        ::Pokemon.create!(
          pokemon_template: template,
          team: team,
          nickname: nickname,
          gender: [::Pokemon::MALE, ::Pokemon::FEMALE].sample,
          nature: Nature::LIST.sample,
          weight: template.weight || rand(10.0..150.0).round(2),
          ivs: ivs,
          evs: evs,
          lvl: 50,
          teratype: template.types.first || Types::LIST.sample
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
