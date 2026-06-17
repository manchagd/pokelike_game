# frozen_string_literal: true

module Contracts
  module Consumers
    class SelectLeadsContract < Dry::Validation::Contract
      params do
        required(:battle_id).filled(:string)
        required(:players).array(:hash) do
          required(:player_id).filled(:string)
          required(:lead).filled(:integer)
        end
      end
    end
  end
end
