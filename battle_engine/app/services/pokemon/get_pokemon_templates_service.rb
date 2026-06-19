# frozen_string_literal: true

module Services
  module Pokemon
    class GetPokemonTemplatesService
      BATCH_SIZE = 200

      def call(player_id:)
        PokemonTemplate.order(:id).find_in_batches(batch_size: BATCH_SIZE) do |batch|
          Publishers::PlayerEventsPublisher.publish(
            Messages::PlayerEvents::Events::POKEMON_TEMPLATES_LIST,
            Messages::PlayerEvents::Payloads.pokemon_templates_list(player_id, batch)
          )
        end
      end
    end
  end
end
