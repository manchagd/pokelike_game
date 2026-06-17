# frozen_string_literal: true

class Position < ApplicationRecord
  belongs_to :field
  belongs_to :pokemon_snapshot, class_name: 'PokemonBattleSnapshot'

  validates :group, presence: true, numericality: { only_integer: true }
  validates :side, inclusion: { in: %w[A B] }, allow_nil: true
end
