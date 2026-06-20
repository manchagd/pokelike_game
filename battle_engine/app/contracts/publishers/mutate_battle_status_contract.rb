# frozen_string_literal: true

module Contracts
  module Publishers
    class MutateBattleStatusContract < Dry::Validation::Contract
      params Contracts::Common::MutateBattleStatusContract.schema
    end
  end
end
