# frozen_string_literal: true

module Contracts
  module Consumers
    class DeleteTeamContract < Dry::Validation::Contract
      params do
        required(:player_id).filled(:integer)
        required(:team_id).filled(:integer)
        optional(:timestamp).maybe(:string)
      end
    end
  end
end
