# frozen_string_literal: true

module Contracts
  module Publishers
    class TeamDetailsContract < Dry::Validation::Contract
      params do
        required(:player_id).filled(:integer)
        required(:team_id).filled(:integer)
        required(:name).filled(:string)
        required(:pokemons).array(:hash) do
          required(:id).filled(:integer)
          required(:pokemon_template_id).filled(:integer)
          required(:name).filled(:string)
          required(:types).array(:string)
          required(:stats).filled(:hash)
          optional(:nickname).maybe(:string)
          required(:gender).maybe(:string)
          required(:nature).filled(:string)
          required(:weight).filled(:float)
          required(:lvl).filled(:integer)
          optional(:teratype).maybe(:string)
          required(:ivs).filled(:hash)
          required(:evs).filled(:hash)
          optional(:sprite).maybe(:string)
          required(:selected_moves).array(:integer)
        end
        optional(:timestamp).maybe(:string)
      end
    end
  end
end
