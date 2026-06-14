# frozen_string_literal: true

module Services
  module Consumers
    class RegisterEvent
      def call(payload)
        BattleEngine.logger.info("[Service] Processing registration for player: #{payload[:name]}")

        player = Player.includes(battles: :players).find_or_create_by!(name: payload[:name])

        Publishers::PlayerEventsPublisher.publish(
          Messages::PlayerEvents::Events::INFO,
          Messages::PlayerEvents::Payloads.info(player)
        )
      end
    end
  end
end
