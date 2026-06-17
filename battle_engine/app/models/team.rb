# frozen_string_literal: true

class Team < ApplicationRecord
  has_many :pokemons, dependent: :destroy
  belongs_to :player

  validates :name, presence: true, uniqueness: { scope: :player_id }
end
