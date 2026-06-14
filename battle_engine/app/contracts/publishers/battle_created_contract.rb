# frozen_string_literal: true

module Contracts
  module Publishers
    class BattleCreatedContract < Dry::Validation::Contract
      params do
        required(:player_id).filled(:integer)
        required(:battle_id).filled(:string)
        optional(:timestamp).maybe(:string)
      end
    end
  end
end
