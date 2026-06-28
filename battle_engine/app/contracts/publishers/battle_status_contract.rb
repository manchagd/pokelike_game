# frozen_string_literal: true

module Contracts
  module Publishers
    class BattleStatusContract < Dry::Validation::Contract
      params do
        required(:external_id).filled(:string)
        required(:status).filled(:string)
        required(:turn).filled(:integer)
        optional(:timestamp).maybe(:string)
        optional(:players).array(:hash) do
          required(:id).filled(:integer)
          required(:name).filled(:string)
          required(:team).filled(:string)
          required(:pokemons).array(:hash) do
            required(:id).filled(:integer)
            required(:hp).filled(:integer)
            required(:max_hp).filled(:integer)
            required(:level).filled(:integer)
            required(:lead).filled(:bool)
            optional(:status_condition).maybe(:hash)
            optional(:stat_stages).maybe(:hash)
            optional(:turn_afflictions).maybe(:hash)
            optional(:locked_condition).maybe(:hash)
            optional(:attack_log).maybe(:array)
            required(:name).filled(:string)
            required(:pokemon_name).filled(:string)
            required(:types).array(:string)
            required(:sprite_url).maybe(:string)
            optional(:field_position).maybe(:hash) do
              required(:group).filled(:integer)
              required(:side).filled(:string)
            end
            required(:attacks).array(:hash) do
              required(:id).filled(:integer)
              required(:name).filled(:string)
              optional(:power).maybe(:integer)
              optional(:accuracy).maybe(:integer)
              required(:pp).filled(:integer)
              required(:category).filled(:string)
              required(:types).array(:string)
              optional(:meta).maybe(:hash) do
                optional(:enforce_switch).filled(:bool)
              end
            end
          end
        end
        optional(:battle_logs).array(:hash) do
          required(:message).filled(:string)
          required(:created_at).filled(:string)
        end
      end
    end
  end
end
