# frozen_string_literal: true

class PokemonTemplate < ApplicationRecord
  has_and_belongs_to_many :moves, join_table: :pokemon_template_moves
  validate :types_exists?

  private
  def types_exists?
    unkonwn_types = types - Types.list

    return if unkonwn_types.empty?

    errors.add(:types, "#{unkonwn_types} must exist")
  end
end
