# frozen_string_literal: true

module Services
  module Moves
    module Handlers
      class Damage
        def self.call(pokemon, target, move)
          # Formulas.critical_factor(pokemon, move)

          if move.category == Move::PHYSICAL
            attack = pokemon.atk_stat * Formulas.stage_multiplier(pokemon.atk_stage)
            defense = target.def_stat * Formulas.stage_multiplier(target.def_stage)
          else
            attack = pokemon.sp_atk_stat * Formulas.stage_multiplier(pokemon.sp_atk_stage)
            defense = target.sp_def_stat * Formulas.stage_multiplier(target.sp_def_stage)
          end

          stab = Formulas.calculate_stab(pokemon, move)
          type_multiplier = Types.calc_multiplier(move.type, target.pokemon.pokemon_template.types)
          damage = Formulas.damage_formula(
            attack: attack,
            defense: defense,
            lvl: pokemon.lvl,
            power: move.power,
            stab: stab,
            type: type_multiplier
          )

          target.update!(hp: target.hp - damage)
          BattleEngine.logger.info("#{target.pokemon.pokemon_template.name} took #{damage} damage")
        end
      end
    end
  end
end

# implementar specs para acción de daño
