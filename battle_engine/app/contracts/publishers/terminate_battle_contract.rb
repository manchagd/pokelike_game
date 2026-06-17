# frozen_string_literal: true

module Contracts
  module Publishers
    class TerminateBattleContract < Dry::Validation::Contract
      params do
        required(:battle_id).filled(:string)
        required(:reason).filled(:string)
        optional(:timestamp).maybe(:string)
      end
    end
  end
end
