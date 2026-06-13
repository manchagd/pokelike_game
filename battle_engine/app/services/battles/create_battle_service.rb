# frozen_string_literal: true

module Services
  module Battles
    class CreateBattleService
      def call(player_id:, team_id:)
        # Find the player (raises ActiveRecord::RecordNotFound if not found)
        player = Player.find(player_id)

        # team_id is currently ignored placeholder due to data constraints
        BattleEngine.logger.info(
          "[CreateBattleService] Initializing battle for player: #{player.name} " \
          "(player_id: #{player_id}, team_id placeholder: #{team_id})"
        )

        ActiveRecord::Base.transaction do
          # Create the respective field
          field = Field.create!

          battle = Battle.create!(field:)

          battle.battle_players.create!(player:)

          battle
        end
      end
    end
  end
end
