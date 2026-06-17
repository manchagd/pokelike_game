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
          required(:player_id).filled(:string)
          optional(:move_id).maybe(:string)
          optional(:monster_id).maybe(:string)
          optional(:targets).maybe(:array)
        end
      end

      rule(:actions) do
        next unless values[:actions].is_a?(Array)

        values[:actions].each_with_index do |action_item, index|
          if action_item[:action] == 'attack'
            if action_item[:move_id].nil? || action_item[:move_id].to_s.strip.empty?
              key([:actions, index, :move_id]).failure('must be filled for attack action')
            end
            if action_item[:targets].nil? || !action_item[:targets].is_a?(Array) || action_item[:targets].empty?
              key([:actions, index, :targets]).failure('must be filled for attack action')
            end
          elsif action_item[:action] == 'switch'
            if action_item[:monster_id].nil? || action_item[:monster_id].to_s.strip.empty?
              key([:actions, index, :monster_id]).failure('must be filled for switch action')
            end
          end
        end
      end
    end
  end
end
