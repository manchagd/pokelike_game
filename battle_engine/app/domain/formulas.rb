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

  def self.damage_formula(
    attack:,
    defense:,
    lvl:,
    power:,
    targets: 1,
    pb: 1,
    weather: 1,
    glaive_rush: 1,
    critical: 1,
    stab: 1,
    type: 1,
    burn: 1,
    other: 1,
    z_move: 1,
    terashield: 1
  )
    attack = attack.to_i
    defense = defense.to_i
    lvl = lvl.to_i
    power = power.to_i
    targets = targets.to_i
    pb = pb.to_i
    weather = weather.to_i
    glaive_rush = glaive_rush.to_i
    critical = critical.to_i
    stab = stab.to_i
    type = type.to_i
    burn = burn.to_i
    other = other.to_i
    z_move = z_move.to_i
    terashield = terashield.to_i

    (((((2 * lvl) / 5).floor + 2) * power * (attack / defense) / 50) + 2) * targets * pb * weather * glaive_rush * critical * stab * type * burn * other * z_move * terashield
  end
end
