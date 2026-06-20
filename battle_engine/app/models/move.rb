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
  validates :pp, :category, :type, :handler, presence: true
  validates :power, numericality: { only_integer: true }, allow_nil: true
  validates :category, inclusion: { in: CATEGORIES }
  validates :pokeapi_id, uniqueness: { allow_nil: true }

  enum :handler, {
    unique: 'Unique',
    damage_ailment: 'DamageAilment',
    ailment: 'Ailment',
    net_good_stats: 'NetGoodStats',
    field_effect: 'FieldEffect',
    damage: 'Damage',
    damage_lower: 'DamageLower',
    ohko: 'Ohko',
    force_switch: 'ForceSwitch',
    damage_raise: 'DamageRaise',
    damage_heal: 'DamageHeal',
    whole_field_effect: 'WholeFieldEffect',
    heal: 'Heal',
    swagger: 'Swagger'
  }

  validate :types_exists?

  def handler
    self.class.handlers[super] || super
  end

  private

  def types_exists?
    unkonwn_types = [type, secondary_type].compact - Types::LIST

    return false if unkonwn_types.empty?

    errors.add(:type, "#{unkonwn_types} must exist")
  end
end

# Agregar nuevo handler para damage_recoil (ej: double edge, high jump kick, rock smash, etc)
