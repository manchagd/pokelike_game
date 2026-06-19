# frozen_string_literal: true

module Services
  module Consumers
    class DeleteTeamEvent
      def call(payload)
        player_id = payload[:player_id]
        team_id = payload[:team_id]
        BattleEngine.logger.info("[Service] Processing delete_team for player: #{player_id}, team: #{team_id}")

        Services::Teams::DeleteTeamService.new.call(player_id: player_id, team_id: team_id)
      rescue StandardError => e
        BattleEngine.logger.error("[Service] Error processing delete_team: #{e.class} - #{e.message}")
      end
    end
  end
end
