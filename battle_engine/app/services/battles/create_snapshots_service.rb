# frozen_string_literal: true

module Services
  module Battles
    class CreateSnapshotsService
      def call(battle:, player:, team_id:)
        team = Team.find_by!(id: team_id, player: player)

        BattleEngine.logger.info(
          "[CreateSnapshotsService] Creating snapshots for battle: #{battle.external_id}, " \
          "player: #{player.name}, team: #{team.name} (#{team.pokemons.count} pokemons)"
        )

        team.pokemons.each do |pokemon|
          PokemonBattleSnapshot.create!(
            battle: battle,
            pokemon: pokemon,
            hp: pokemon.hp_stat,
            status_condition: {},
            stat_stages: {},
            turn_afflictions: {},
            locked_condition: {},
            attack_log: []
          )
        end
      end
    end
  end
end
