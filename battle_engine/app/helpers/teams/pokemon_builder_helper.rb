# frozen_string_literal: true

module Helpers
  module Teams
    module PokemonBuilderHelper
      DEFAULT_IVS = {
        'hp' => 31, 'atk' => 31, 'def' => 31, 'sp_atk' => 31, 'sp_def' => 31, 'spd' => 31
      }.freeze

      DEFAULT_EVS = {
        'hp' => 0, 'atk' => 0, 'def' => 0, 'sp_atk' => 0, 'sp_def' => 0, 'spd' => 0
      }.freeze

      def determine_nickname(pkmn_data:, template:)
        (pkmn_data[:nickname].presence || template.name)[0...10]
      end

      def determine_ivs(pkmn_data:)
        DEFAULT_IVS.merge((pkmn_data[:ivs] || {}).transform_keys(&:to_s))
      end

      def determine_evs(pkmn_data:)
        DEFAULT_EVS.merge((pkmn_data[:evs] || {}).transform_keys(&:to_s))
      end

      def determine_gender(pkmn_data:, template:)
        gender = pkmn_data[:gender].presence

        return nil if template.gender_rate.nil? || template.gender_rate == -1
        return ::Pokemon::MALE if template.gender_rate.zero?
        return ::Pokemon::FEMALE if template.gender_rate == 8
        return gender if [::Pokemon::MALE, ::Pokemon::FEMALE].include?(gender)

        rand(8) < template.gender_rate ? ::Pokemon::FEMALE : ::Pokemon::MALE
      end

      def determine_nature(pkmn_data:, fallback_nature:)
        nature = pkmn_data[:nature].presence
        return fallback_nature if nature.nil? || !Nature::LIST.include?(nature)

        nature
      end

      def determine_weight(template:)
        template.weight || rand(10.0..150.0).round(2)
      end

      def determine_teratype(template:)
        template.types.first || Types::LIST.sample
      end

      def build_and_create_pokemon(team, template, pkmn_data)
        nickname = determine_nickname(pkmn_data:, template:)
        ivs = determine_ivs(pkmn_data:)
        evs = determine_evs(pkmn_data:)
        gender = determine_gender(pkmn_data:, template:)
        nature = determine_nature(pkmn_data:, fallback_nature: Nature::LIST.sample)
        weight = determine_weight(template:)
        teratype = determine_teratype(template:)

        ::Pokemon.create!(
          pokemon_template: template,
          team: team,
          nickname: nickname,
          gender: gender,
          nature: nature,
          weight: weight,
          ivs: ivs,
          evs: evs,
          lvl: 50,
          teratype: teratype
        )
      end
    end
  end
end
