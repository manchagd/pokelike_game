# frozen_string_literal: true

module Services
  module Consumers
    class SelectLeadsEvent
      def call(payload)
        battle_id = payload[:battle_id]
        player_leads = payload[:players]

        battle = Battle.find_by!(external_id: battle_id)

        ActiveRecord::Base.transaction do
          # Group by player's team side/group
          by_group = player_leads.group_by do |entry|
            bp = battle.battle_players.find_by!(player_id: entry[:player_id])
            bp.group
          end

          by_group.each do |group_name, entries|
            # For 1v1 layout, we only take the first player per group
            entry = entries.first
            pokemon_snap_id = entry[:lead]

            # Retrieve snapshot and verify ownership
            snapshot = battle.pokemon_battle_snapshots.find(pokemon_snap_id)
            raise 'Invalid snapshot ownership' unless snapshot.pokemon.team.player_id == entry[:player_id].to_i

            # Position lead pokemon on field
            Positions.create!(
              field: battle.field,
              group: group_name == 'A' ? 1 : 2,
              side: group_name == 'A' ? 'A' : 'B',
              pokemon_id: snapshot.pokemon_id
            )
          end

          # Mutate state to in_progress
          battle.in_progress!
        end

        # Broadcast updated sync state to real-time server
        Publishers::BattleEventsPublisher.publish(
          Messages::BattleEvents::Events::BATTLE_STATUS,
          Messages::BattleEvents::Payloads.battle_status(battle)
        )
      end
    end
  end
end
