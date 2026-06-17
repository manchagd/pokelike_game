# frozen_string_literal: true

class Pokemon < ApplicationRecord
  GENDERS = [
    MALE = 'Male',
    FEMALE = 'Female'
  ].freeze

  belongs_to :team
  belongs_to :pokemon_template
  has_many :attacks, dependent: :destroy
  has_many :moves, through: :attacks
  has_many :pokemon_battle_snapshots, dependent: :destroy

  validates :nickname, length: { maximum: 10 }
  validates :gender, inclusion: { in: GENDERS }, allow_nil: true
  validates :nature, inclusion: { in: Nature::LIST }
  validates :weight, presence: true, numericality: true
  validates :lvl, presence: true, numericality: { only_integer: true }
  validates :teratype, inclusion: { in: Types::LIST }, allow_nil: true

  before_save :calculate_and_set_stats

  def hp_stat
    stats['hp']
  end

  def atk_stat
    stats['atk']
  end

  def def_stat
    stats['def']
  end

  def sp_atk_stat
    stats['sp_atk']
  end

  def sp_def_stat
    stats['sp_def']
  end

  def spd_stat
    stats['spd']
  end

  private

  def calculate_and_set_stats
    return if pokemon_template.nil?

    self.stats = {
      'hp' => calculate_hp,
      'atk' => calculate_other_stat(:atk),
      'def' => calculate_other_stat(:def),
      'sp_atk' => calculate_other_stat(:sp_atk),
      'sp_def' => calculate_other_stat(:sp_def),
      'spd' => calculate_other_stat(:spd)
    }
  end

  def calculate_hp
    Formulas.hp_formula(
      base_hp: pokemon_template.stats['hp'],
      iv_hp: ivs['hp'],
      ev_hp: evs['hp'],
      level: lvl
    )
  end

  def calculate_other_stat(stat_key)
    Formulas.other_stat_formula(
      base_stat: pokemon_template.stats[stat_key.to_s],
      iv_stat: ivs[stat_key.to_s],
      ev_stat: evs[stat_key.to_s],
      level: lvl,
      nature_modifier: Nature.modifier_for(nature, stat_key)
    )
  end
end
