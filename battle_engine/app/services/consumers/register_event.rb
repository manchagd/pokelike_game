# frozen_string_literal: true

module Services
  module Consumers
    class RegisterEvent
      def call(payload)
        BattleEngine.logger.info("[Service] Processing registration for player: #{payload[:name]}")

        player = Player.find_or_create_by!(name: payload[:name])

        Publishers::PlayerEventsPublisher.publish(
          ::PlayerEventsMessages::INFO,
          player.info_event_payload
        )
      end
    end
  end
end
