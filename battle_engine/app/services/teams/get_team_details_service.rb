# frozen_string_literal: true

module Services
  module Teams
    class GetTeamDetailsService
      def call(player_id:, team_id:)
        player = Player.find(player_id)
        team = player.teams.find(team_id)

        Publishers::PlayerEventsPublisher.publish(
          Messages::PlayerEvents::Events::TEAM_DETAILS,
          Messages::PlayerEvents::Payloads.team_details(team)
        )
      end
    end
  end
end
