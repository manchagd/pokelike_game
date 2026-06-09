# frozen_string_literal: true

module Services
  module Consumers
    class RegisterEvent
      def call(payload)
        BattleEngine.logger.info("[Service] Processing registration for player: #{payload[:name]}")
        # Aquí irá la lógica de persistencia del jugador, etc.
      end
    end
  end
end
