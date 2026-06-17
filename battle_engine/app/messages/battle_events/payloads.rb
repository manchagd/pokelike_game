# frozen_string_literal: true

module Messages
  module BattleEvents
    module Payloads
      module_function

      def battle_status(battle)
        {
          external_id: battle.external_id,
          status: battle.status,
          turn: battle.turn
        }
      end

      def terminate_battle(battle_id, reason)
        {
          battle_id: battle_id,
          reason: reason
        }
      end
    end
  end
end
