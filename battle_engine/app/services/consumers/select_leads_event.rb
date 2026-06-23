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
            entries.each.with_index(1) do |entry, index|
              pokemon_snap_id = entry[:lead]

              # Retrieve snapshot and verify ownership
              snapshot = battle.pokemon_battle_snapshots.find(pokemon_snap_id)
              raise 'Invalid snapshot ownership' unless snapshot.player_id == entry[:player_id].to_i

              # Position lead pokemon on field
              Position.create!(
                field: battle.field,
                group: index,
                side: group_name,
                pokemon_snapshot_id: snapshot.id
              )
            end
          end

          # Mutate state to in_progress
          battle.turn = 1
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
