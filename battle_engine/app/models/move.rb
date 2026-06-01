# frozen_string_literal: true

class Move < ApplicationRecord
  self.inheritance_column = nil
  PHYSICAL = "Physical"
  SPECIAL = "Special"
  STATUS = "Status"

  CATEGORIES = [PHYSICAL, SPECIAL, STATUS].freeze

  has_and_belongs_to_many :pokemon_templates, join_table: :pokemon_template_moves

  validates :name, presence: true, uniqueness: true  
  validates :pp, :category, :type,  presence: true
  validates :power, numericality: { only_integer: true }, allow_nil: true
  validates :category, inclusion: { in: CATEGORIES }
  validate :types_exists?

  private
  def types_exists?
    unkonwn_types = ([type] + [secondary_type]) - Types::LIST

    return if unkonwn_types.empty?

    errors.add(:type, "#{unkonwn_types} must exist")
  end
end
