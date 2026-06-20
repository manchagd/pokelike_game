# frozen_string_literal: true

module Services
  module Teams
    class MutateTeamService
      def call(player_id:, name:, pokemons:, team_id: nil)
        player = Player.find(player_id)

        if team_id.present?
          Services::Teams::UpdateTeamService.new.call(
            player: player,
            team_id: team_id,
            name: name,
            pokemons: pokemons
          )
        else
          Services::Teams::CreateTeamService.new.call(
            player: player,
            name: name,
            pokemons: pokemons
          )
        end

        # Broadcast updated teams_info to player channel
        Publishers::PlayerEventsPublisher.publish(
          Messages::PlayerEvents::Events::TEAMS_INFO,
          Messages::PlayerEvents::Payloads.teams_info(player)
        )
      end
    end
  end
end
