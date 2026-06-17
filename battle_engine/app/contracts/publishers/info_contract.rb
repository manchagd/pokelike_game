# frozen_string_literal: true

module Contracts
  module Publishers
    class InfoContract < Dry::Validation::Contract
      params do
        required(:player).hash do
          required(:id).filled(:integer)
          required(:name).filled(:string)
          required(:teams).array(:hash) do
            required(:id).filled(:integer)
            required(:name).filled(:string)
            required(:pokemons).array(:hash) do
              required(:name).filled(:string)
              required(:types).array(:string)
            end
          end
          required(:battle_history).hash do
            required(:victories).filled(:integer)
            required(:defeats).filled(:integer)
            required(:history).array(:string)
          end
        end
        optional(:battles).array(:hash) do
          required(:id).filled
          required(:players).array(:hash) do
            required(:name).filled(:string)
            required(:team).filled(:string)
          end
        end
        optional(:timestamp).maybe(:string)
      end
    end
  end
end
