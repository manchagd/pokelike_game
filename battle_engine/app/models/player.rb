# frozen_string_literal: true

class Player < ApplicationRecord
  has_many :teams
  has_and_belongs_to_many :battles, join_table: 'battle_players'

  validates :name, presence: true, uniqueness: true
end
