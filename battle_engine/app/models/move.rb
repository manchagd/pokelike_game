# frozen_string_literal: true

require 'pry'

class Move < ApplicationRecord
  self.inheritance_column = nil
  PHYSICAL = 'Physical'
  SPECIAL = 'Special'
  STATUS = 'Status'

  CATEGORIES = [PHYSICAL, SPECIAL, STATUS].freeze

  has_and_belongs_to_many :pokemon_templates, join_table: :pokemon_template_moves

  validates :name, presence: true, uniqueness: true
  validates :pp, :category, :type,  presence: true
  validates :power, numericality: { only_integer: true }, allow_nil: true
  validates :category, inclusion: { in: CATEGORIES }
  validates :pokeapi_id, uniqueness: { allow_nil: true }
  validate :types_exists?

  private

  def types_exists?
    unkonwn_types = [type, secondary_type].compact - Types::LIST

    return false if unkonwn_types.empty?

    errors.add(:type, "#{unkonwn_types} must exist")
  end
end
