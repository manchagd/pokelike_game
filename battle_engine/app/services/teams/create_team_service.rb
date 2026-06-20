# frozen_string_literal: true

module Services
  module Teams
    class CreateTeamService
      DEFAULT_IVS = {
        'hp' => 31, 'atk' => 31, 'def' => 31, 'sp_atk' => 31, 'sp_def' => 31, 'spd' => 31
      }.freeze

      DEFAULT_EVS = {
        'hp' => 0, 'atk' => 0, 'def' => 0, 'sp_atk' => 0, 'sp_def' => 0, 'spd' => 0
      }.freeze

      def call(player:, name:, pokemons:)
        final_name = resolve_name(player, name)

        ActiveRecord::Base.transaction do
          team = player.teams.create!(name: final_name)
          create_pokemons(team, pokemons)
        end
      end

      private

      def resolve_name(player, name)
        duplicate_exists = player.teams.exists?(name: name)
        duplicate_exists ? "#{name} (#{Time.now.to_i})" : name
      end

      def create_pokemons(team, pokemons)
        pokemons.each do |pkmn_data|
          template = ::PokemonTemplate.find(pkmn_data[:pokemon_template_id])
          pokemon = build_and_create_pokemon(team, template, pkmn_data)

          (pkmn_data[:moves] || []).each do |move_id|
            pokemon.attacks.create!(move_id: move_id)
          end
        end
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
    end
  end
end
