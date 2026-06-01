# frozen_string_literal: true

class Team < ApplicationRecord
  has_and_belongs_to_many :pokemons, join_table: :team_pokemons
  belongs_to :player

  validates :name, presence: true, uniqueness: true
end
