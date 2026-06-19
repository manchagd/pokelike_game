# frozen_string_literal: true

module Services
  module Teams
    class CreateTeamService
      def call(player_id:, name:, pokemons:, team_id: nil)
        player = Player.find(player_id)

        # Resolve team name uniqueness scoped to player_id (excluding this team if updating)
        final_name = name
        duplicate_exists = if team_id.present?
                             player.teams.where.not(id: team_id).exists?(name: final_name)
                           else
                             player.teams.exists?(name: final_name)
                           end

        final_name = "#{name} (#{Time.now.to_i})" if duplicate_exists

        ActiveRecord::Base.transaction do
          team = if team_id.present?
                   t = player.teams.find(team_id)
                   t.update!(name: final_name)
                   t.pokemons.destroy_all
                   t
                 else
                   player.teams.create!(name: final_name)
                 end

          pokemons.each do |pkmn_data|
            template = ::PokemonTemplate.find(pkmn_data[:pokemon_template_id])

            nickname = (pkmn_data[:nickname].presence || template.name)[0...10]
            gender = [::Pokemon::MALE, ::Pokemon::FEMALE].sample
            nature = Nature::LIST.sample
            weight = template.weight || rand(10.0..150.0).round(2)
            teratype = template.types.first || Types::LIST.sample

            # Default IVs to 31 and EVs to 0
            ivs = {
              'hp' => 31, 'atk' => 31, 'def' => 31, 'sp_atk' => 31, 'sp_def' => 31, 'spd' => 31
            }.merge((pkmn_data[:ivs] || {}).transform_keys(&:to_s))

            evs = {
              'hp' => 0, 'atk' => 0, 'def' => 0, 'sp_atk' => 0, 'sp_def' => 0, 'spd' => 0
            }.merge((pkmn_data[:evs] || {}).transform_keys(&:to_s))

            pokemon = ::Pokemon.create!(
              pokemon_template: template,
              team: team,
              nickname: nickname,
              gender: gender,
              nature: nature,
              weight: weight,
              ivs: ivs,
              evs: evs,
              lvl: 50,
              teratype: teratype
            )

            # Associate moves
            (pkmn_data[:moves] || []).each do |move_id|
              pokemon.attacks.create!(move_id: move_id)
            end
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
end
