# frozen_string_literal: true

module Contracts
  module Consumers
    class GetPokemonTemplatesContract < Dry::Validation::Contract
      params do
        required(:player_id).filled(:integer)
        optional(:timestamp).maybe(:string)
      end
    end
  end
end
