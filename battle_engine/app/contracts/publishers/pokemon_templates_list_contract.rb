# frozen_string_literal: true

module Contracts
  module Publishers
    class PokemonTemplatesListContract < Dry::Validation::Contract
      params do
        required(:player_id).filled(:integer)
        required(:pokemon_templates).array(:hash) do
          required(:id).filled(:integer)
          required(:name).filled(:string)
          required(:types).array(:string)
          required(:stats).filled(:hash)
          optional(:sprite).maybe(:string)
        end
        optional(:timestamp).maybe(:string)
      end
    end
  end
end
