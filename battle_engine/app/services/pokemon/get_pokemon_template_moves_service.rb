# frozen_string_literal: true

module Services
  module Pokemon
    class GetPokemonTemplateMovesService
      def call(player_id:, pokemon_template_id:)
        template = PokemonTemplate.find(pokemon_template_id)
        moves = template.moves.to_a

        Publishers::PlayerEventsPublisher.publish(
          Messages::PlayerEvents::Events::POKEMON_TEMPLATE_MOVES_LIST,
          Messages::PlayerEvents::Payloads.pokemon_template_moves_list(player_id, pokemon_template_id, moves)
        )
      end
    end
  end
end
