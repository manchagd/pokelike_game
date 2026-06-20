# frozen_string_literal: true

module Contracts
  module Publishers
    class BattlesInfoContract < Dry::Validation::Contract
      params do
        required(:player_id).filled(:integer)
        required(:battle_history).hash do
          required(:victories).filled(:integer)
          required(:defeats).filled(:integer)
          required(:history).array(:string)
        end
        required(:battles).array(:hash) do
          required(:id).filled(:string)
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
