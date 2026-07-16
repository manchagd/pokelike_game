# frozen_string_literal: true

module Services
  module Teams
    class CreateTeamService
      include Helpers::Teams::PokemonBuilderHelper

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
    end
  end
end
