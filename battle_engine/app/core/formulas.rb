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
    stab:,
    type:,
    critical:,
    targets: 1,
    pb: 1,
    weather: 1,
    glaive_rush: 1,
    burn: 1,
    other: 1,
    z_move: 1,
    terashield: 1
  )
    attack = attack.to_f
    defense = defense.to_f
    lvl = lvl.to_i
    power = power.to_f
    targets = targets.to_i
    pb = pb.to_i
    weather = weather.to_i
    glaive_rush = glaive_rush.to_i
    critical = critical.to_i
    burn = burn.to_i
    other = other.to_i
    z_move = z_move.to_i
    terashield = terashield.to_i
    random = random_factor

    # debug_formula = "((((((2 * #{lvl}) / 5.0) + 2) * #{power} * (#{attack} / #{defense})) / 50.0) + 2) * #{targets} * #{pb} * #{weather} * #{glaive_rush} * #{critical} * #{stab} * #{type} * #{burn} * #{other} * #{z_move} * #{terashield} * #{random}"

    # puts debug_formula

    damage = ((((((2 * lvl) / 5.0) + 2).round(half: :down) * power * (attack / defense)) / 50.0) + 2).round(half: :down) * targets * pb * weather * glaive_rush * critical * stab * type
    damage = damage.floor * burn * other * z_move * terashield * random
    damage.round(half: :down)
  end

  def self.calculate_stab(pokemon, move)
    pokemon.pokemon.pokemon_template.types.include?(move.type) ? 1.5 : 1
  end

  def self.random_factor
    rand(0.85..1.0)
  end

  def self.stage_multiplier(stage, step = 2)
    return 1.0 if stage.nil?

    stage.negative? ? step.to_f / (step + stage) : (step + stage).to_f / step
  end

  def self.accuracy_formula(pokemon, target, move)
    modifier = 1
    micle_berry = 1
    affection = 0
    adjusted_stage = pokemon.accuracy_stage - target.evasion_stage
    adjusted_accuracy = stage_multiplier(adjusted_stage, 3)

    (move.accuracy * modifier * adjusted_accuracy * micle_berry) - affection
  end

  def self.critical_chance(pokemon, move)
    critical_factor = pokemon.crit_stage + move.meta.fetch('crit_rate', 0)

    case critical_factor
    when 0
      1.0 / 24.0
    when 1
      1.0 / 8.0
    when 2
      1.0 / 2.0
    else
      1.0
    end
  end
end

# implementar formula para determinar golpe critico
