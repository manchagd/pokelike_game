# frozen_string_literal: true

module Contracts
  module Consumers
    class TurnActionsContract < Dry::Validation::Contract
      params do
        required(:battle_id).filled(:string)
        required(:turn).filled(:integer)
        optional(:timestamp).maybe(:string)
        required(:actions).array(:hash) do
          required(:action).filled(:string, included_in?: %w[attack switch])
          required(:player_id).filled(:integer)
          optional(:move_id).maybe(:integer)
          optional(:pokemon_id).maybe(:integer)
          optional(:targets).maybe { array? & each(:string) }
        end
      end

      rule(:actions) do
        next unless values[:actions].is_a?(Array)

        values[:actions].each_with_index do |action_item, index|
          if action_item[:action] == 'attack'
            key([:actions, index, :move_id]).failure('must be filled for attack action') if action_item[:move_id].nil?
            if action_item[:targets].nil? || !action_item[:targets].is_a?(Array) || action_item[:targets].empty?
              key([:actions, index, :targets]).failure('must be filled for attack action')
            end
          elsif action_item[:action] == 'switch'
            key([:actions, index, :pokemon_id]).failure('must be filled for switch action') if action_item[:pokemon_id].nil?
          end
        end
      end
    end
  end
end
