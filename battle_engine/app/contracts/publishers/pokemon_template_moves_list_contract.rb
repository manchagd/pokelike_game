# frozen_string_literal: true

module Contracts
  module Publishers
    class PokemonTemplateMovesListContract < Dry::Validation::Contract
      params do
        required(:player_id).filled(:integer)
        required(:pokemon_template_id).filled(:integer)
        required(:moves).array(:hash) do
          required(:id).filled(:integer)
          required(:name).filled(:string)
          required(:type).filled(:string)
          required(:category).filled(:string)
          optional(:power).maybe(:integer)
          optional(:accuracy).maybe(:integer)
          required(:pp).filled(:integer)
        end
        optional(:timestamp).maybe(:string)
      end
    end
  end
end
