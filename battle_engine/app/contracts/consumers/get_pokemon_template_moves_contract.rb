# frozen_string_literal: true

module Contracts
  module Consumers
    class GetPokemonTemplateMovesContract < Dry::Validation::Contract
      params do
        required(:player_id).filled(:integer)
        required(:pokemon_template_id).filled(:integer)
        optional(:timestamp).maybe(:string)
      end
    end
  end
end
