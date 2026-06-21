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

        gender = pkmn_data[:gender].presence
        if template.gender_rate.nil? || template.gender_rate == -1
          gender = nil
        elsif template.gender_rate == 0
          gender = ::Pokemon::MALE
        elsif template.gender_rate == 8
          gender = ::Pokemon::FEMALE
        elsif ![::Pokemon::MALE, ::Pokemon::FEMALE].include?(gender)
          gender = pokemon.gender || determine_gender(template)
        end

        nature = pkmn_data[:nature].presence
        nature = pokemon.nature unless Nature::LIST.include?(nature)

        pokemon.update!(
          pokemon_template: template,
          nickname: nickname,
          gender: gender,
          nature: nature,
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

        gender = pkmn_data[:gender].presence
        if template.gender_rate.nil? || template.gender_rate == -1
          gender = nil
        elsif template.gender_rate == 0
          gender = ::Pokemon::MALE
        elsif template.gender_rate == 8
          gender = ::Pokemon::FEMALE
        elsif ![::Pokemon::MALE, ::Pokemon::FEMALE].include?(gender)
          gender = determine_gender(template)
        end

        ::Pokemon.create!(
          pokemon_template: template,
          team: team,
          nickname: nickname,
          gender: gender,
          nature: (Nature::LIST.include?(pkmn_data[:nature].to_s) ? pkmn_data[:nature].to_s : Nature::LIST.sample),
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

      def determine_gender(template)
        return nil if template.gender_rate.nil? || template.gender_rate == -1

        rand(8) < template.gender_rate ? ::Pokemon::FEMALE : ::Pokemon::MALE
      end
    end
  end
end
