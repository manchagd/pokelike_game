# frozen_string_literal: true

module Contracts
  module Common
    class MutateBattleStatusContract < Dry::Validation::Contract
      params do
        required(:battle_id).filled(:string)
        required(:status).filled(:string, included_in?: %w[not_started setting_up in_progress finished])
        optional(:reason).maybe(:string)
        optional(:timestamp).maybe(:string)
      end
    end
  end
end
