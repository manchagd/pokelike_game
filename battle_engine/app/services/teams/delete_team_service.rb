# frozen_string_literal: true

module Services
  module Teams
    class DeleteTeamService
      def call(player_id:, team_id:)
        player = Player.find(player_id)
        team = player.teams.find(team_id)

        ActiveRecord::Base.transaction do
          pokemons = team.pokemons.to_a

          pokemons.each do |pokemon|
            if pokemon.pokemon_battle_snapshots.exists?
              pokemon.update!(team: nil)
            else
              pokemon.destroy!
            end
          end

          team.pokemons.reload
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
