# frozen_string_literal: true

module Contracts
  module Publishers
    class BattleStatusContract < Dry::Validation::Contract
      params do
        required(:external_id).filled(:string)
        required(:status).filled(:string)
        required(:turn).filled(:integer)
        optional(:timestamp).maybe(:string)
      end
    end
  end
end
