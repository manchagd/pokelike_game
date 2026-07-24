# frozen_string_literal: true

module Services
  module Moves
    module Handlers
      class Damage
        def self.call(pokemon, target, move)
          critical = Formulas.critical_chance(pokemon, move) > rand(0.0..1.0) ? 1.5 : 1
          attack, defense = attack_and_defense_assignation(pokemon, target, critical)

          stab = Formulas.calculate_stab(pokemon, move)
          type_multiplier = Types.calc_multiplier(move.type, target.pokemon.pokemon_template.types)
          damage = Formulas.damage_formula(
            attack: attack,
            defense: defense,
            lvl: pokemon.lvl,
            power: move.power,
            stab: stab,
            type: type_multiplier,
            critical: critical
          )

          target.update!(hp: target.hp - damage)
          BattleEngine.logger.info("#{target.pokemon.pokemon_template.name} took #{damage} damage")
        end

        def self.attack_and_defense_assignation(pokemon, target, critical)
          if move.category == Move::PHYSICAL
            attack_stat = pokemon.atk_stat
            attack_stage = pokemon.atk_stage
            defense_stat = target.def_stat
            defense_stage = target.def_stage
          else
            attack_stat = pokemon.sp_atk_stat
            attack_stage = pokemon.sp_atk_stage
            defense_stat = target.sp_def_stat
            defense_stage = target.sp_def_stage
          end

          [
            attack = critical == 1.5 && attack_stage.negative? ? attack_stat : attack_stat * Formulas.stage_multiplier(attack_stage),
            defense = critical == 1.5 && defense_stage.positive? ? defense_stat : defense_stat * Formulas.stage_multiplier(defense_stage)
          ]
        end
      end
    end
  end
end

# implementar specs para acción de daño
