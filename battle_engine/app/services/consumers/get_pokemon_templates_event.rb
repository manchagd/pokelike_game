# frozen_string_literal: true

module Services
  module Consumers
    class GetPokemonTemplatesEvent
      def call(payload)
        player_id = payload[:player_id]
        BattleEngine.logger.info("[Service] Processing get_pokemon_templates for player: #{player_id}")

        Services::Pokemon::GetPokemonTemplatesService.new.call(player_id: player_id)
      rescue StandardError => e
        BattleEngine.logger.error("[Service] Error processing get_pokemon_templates: #{e.class} - #{e.message}")
      end
    end
  end
end
