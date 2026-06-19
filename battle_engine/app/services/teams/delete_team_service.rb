# frozen_string_literal: true

module Services
  module Teams
    class DeleteTeamService
      def call(player_id:, team_id:)
        player = Player.find(player_id)
        team = player.teams.find(team_id)

        ActiveRecord::Base.transaction do
          archived_team = nil
          team.pokemons.each do |pokemon|
            pokemon.destroy!
          rescue ActiveRecord::InvalidForeignKey
            archived_team ||= player.teams.find_or_create_by!(name: "__archived_#{player.id}__")
            pokemon.update!(team: archived_team)
          end
          team.destroy!
        end

        Publishers::PlayerEventsPublisher.publish(
          Messages::PlayerEvents::Events::TEAMS_INFO,
          Messages::PlayerEvents::Payloads.teams_info(player)
        )
      end
    end
  end
end
