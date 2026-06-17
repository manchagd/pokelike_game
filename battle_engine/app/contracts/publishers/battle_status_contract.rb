# frozen_string_literal: true

module Contracts
  module Publishers
    class BattleStatusContract < Dry::Validation::Contract
      params do
        required(:external_id).filled(:string)
        required(:status).filled(:string)
        required(:turn).filled(:integer)
        optional(:timestamp).maybe(:string)
        optional(:players).array(:hash) do
          required(:name).filled(:string)
          required(:team).filled(:string)
          required(:pokemons).array(:hash) do
            required(:id).filled(:integer)
            required(:hp).filled(:integer)
            required(:max_hp).filled(:integer)
            required(:level).filled(:integer)
            required(:lead).filled(:bool)
            optional(:status_condition).maybe(:hash)
            optional(:stat_stages).maybe(:hash)
            optional(:turn_afflictions).maybe(:hash)
            optional(:locked_condition).maybe(:hash)
            optional(:attack_log).maybe(:array)
            required(:name).filled(:string)
            required(:pokemon_name).filled(:string)
            required(:types).array(:string)
            required(:attacks).array(:hash) do
              required(:id).filled(:integer)
              required(:name).filled(:string)
              optional(:power).maybe(:integer)
              optional(:accuracy).maybe(:integer)
              required(:pp).filled(:integer)
              required(:types).array(:string)
            end
          end
        end
      end
    end
  end
end
