# frozen_string_literal: true

class PokemonTemplate < ApplicationRecord
  has_and_belongs_to_many :moves, join_table: :pokemon_template_moves
end
