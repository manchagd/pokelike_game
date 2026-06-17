# frozen_string_literal: true

class PokemonTemplate < ApplicationRecord
  has_and_belongs_to_many :moves, join_table: :pokemon_template_moves

  validates :name, presence: true, uniqueness: true
  validates :pokeapi_id, uniqueness: { allow_nil: true }
  validates :weight, numericality: { greater_than: 0 }, allow_nil: true
  validate :types_exists?

  private

  def types_exists?
    unkonwn_types = types - Types::LIST

    return false if unkonwn_types.empty?

    errors.add(:types, "#{unkonwn_types} must exist")
  end
end
