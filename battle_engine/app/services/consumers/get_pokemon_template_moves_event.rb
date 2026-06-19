# frozen_string_literal: true

module Services
  module Consumers
    class GetPokemonTemplateMovesEvent
      def call(payload)
        player_id = payload[:player_id]
        pokemon_template_id = payload[:pokemon_template_id]
        BattleEngine.logger.info("[Service] Processing get_pokemon_template_moves for player: #{player_id}, template: #{pokemon_template_id}")

        Services::Pokemon::GetPokemonTemplateMovesService.new.call(
          player_id: player_id,
          pokemon_template_id: pokemon_template_id
        )
      rescue StandardError => e
        BattleEngine.logger.error("[Service] Error processing get_pokemon_template_moves: #{e.class} - #{e.message}")
      end
    end
  end
end
