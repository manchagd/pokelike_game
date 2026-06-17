# frozen_string_literal: true

module Contracts
  module Consumers
    class BattleSyncContract < Dry::Validation::Contract
      params do
        required(:battle_id).filled(:string)
        optional(:timestamp).maybe(:string)
      end
    end
  end
end
