# frozen_string_literal: true

module Contracts
  module Publishers
    class TeamsInfoContract < Dry::Validation::Contract
      params do
        required(:player_id).filled(:integer)
        required(:teams).array(:hash) do
          required(:id).filled(:integer)
          required(:name).filled(:string)
          required(:pokemons).array(:hash) do
            required(:name).filled(:string)
            required(:types).array(:string)
          end
        end
        optional(:timestamp).maybe(:string)
      end
    end
  end
end
