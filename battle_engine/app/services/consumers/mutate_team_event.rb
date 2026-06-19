# frozen_string_literal: true

module Services
  module Consumers
    class MutateTeamEvent
      def call(payload)
        player_id = payload[:player_id]
        name = payload[:name]
        pokemons = payload[:pokemons]
        team_id = payload[:team_id]
        BattleEngine.logger.info("[Service] Processing mutate_team for player: #{player_id}, team name: #{name}, team_id: #{team_id}")

        Services::Teams::MutateTeamService.new.call(
          player_id: player_id,
          name: name,
          pokemons: pokemons,
          team_id: team_id
        )
      rescue StandardError => e
        BattleEngine.logger.error("[Service] Error processing mutate_team: #{e.class} - #{e.message}")
      end
    end
  end
end
