# frozen_string_literal: true

module Formulas
  def self.hp_formula(base_hp:, iv_hp:, ev_hp:, level:)
    base_hp = base_hp.to_i
    iv_hp = iv_hp.to_i
    ev_hp = ev_hp.to_i
    level = level.to_i

    ((((2 * base_hp) + iv_hp + (ev_hp / 4)) * level) / 100).floor + level + 10
  end

  def self.other_stat_formula(base_stat:, iv_stat:, ev_stat:, level:, nature_modifier:)
    base_stat = base_stat.to_i
    iv_stat = iv_stat.to_i
    ev_stat = ev_stat.to_i
    level = level.to_i
    nature_modifier = nature_modifier.to_f

    raw_stat = ((((2 * base_stat) + iv_stat + (ev_stat / 4)) * level) / 100).floor + 5
    (raw_stat * nature_modifier).floor
  end
end
