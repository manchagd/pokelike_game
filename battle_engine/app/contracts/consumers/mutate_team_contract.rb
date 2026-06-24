# frozen_string_literal: true

module Contracts
  module Consumers
    class MutateTeamContract < Dry::Validation::Contract
      params do
        required(:player_id).filled(:integer)
        required(:name).filled(:string)
        required(:pokemons).array(:hash) do
          required(:pokemon_template_id).filled(:integer)
          optional(:nickname).maybe(:string)
          optional(:gender).maybe(:string)
          optional(:nature).maybe(:string)
          optional(:ivs).maybe(:hash)
          optional(:evs).maybe(:hash)
          required(:moves).array(:integer)
        end
        optional(:timestamp).maybe(:string)
        optional(:team_id).maybe(:integer)
      end
    end
  end
end
