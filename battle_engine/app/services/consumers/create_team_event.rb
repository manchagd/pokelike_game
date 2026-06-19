# frozen_string_literal: true

module Services
  module Consumers
    class CreateTeamEvent
      def call(payload)
        player_id = payload[:player_id]
        name = payload[:name]
        pokemons = payload[:pokemons]
        BattleEngine.logger.info("[Service] Processing create_team for player: #{player_id}, team name: #{name}")

        Services::Teams::CreateTeamService.new.call(
          player_id: player_id,
          name: name,
          pokemons: pokemons,
          team_id: payload[:team_id]
        )
      rescue ActiveRecord::RecordNotFound => e
        BattleEngine.logger.error("[Service] Failed to create team, record not found: #{e.message}")
      rescue StandardError => e
        BattleEngine.logger.error("[Service] Unexpected error creating team: #{e.class} - #{e.message}")
      end
    end
  end
end
