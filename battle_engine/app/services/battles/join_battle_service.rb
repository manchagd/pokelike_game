# frozen_string_literal: true

module Services
  module Battles
    class JoinBattleService
      def call(player_id:, battle_id:, team_id:)
        # Find player and battle (raises ActiveRecord::RecordNotFound if missing)
        player = Player.find(player_id)
        battle = Battle.find_by!(external_id: battle_id)

        # team_id is currently ignored placeholder
        BattleEngine.logger.info(
          "[JoinBattleService] Join request for player: #{player.name} to battle: #{battle_id} " \
          "(team_id placeholder: #{team_id})"
        )

        # If already exists, simply return without executing any join logic
        if battle.players.exists?(player.id)
          BattleEngine.logger.info("[JoinBattleService] Player #{player.name} is already in battle #{battle_id}. Returning.")
          return battle
        end

        ActiveRecord::Base.transaction do
          battle.battle_players.create!(player:)

          # Create snapshots for the player's team
          Services::Battles::CreateSnapshotsService.new.call(
            battle: battle,
            player: player,
            team_id: team_id
          )

          battle
        end
      end
    end
  end
end
