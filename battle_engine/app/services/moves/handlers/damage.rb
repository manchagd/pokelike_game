# frozen_string_literal: true

module Services
  module Moves
    module Handlers
      class Damage
        def self.call(pokemon, target, move)
          if move.category == Move::PHYSICAL
            attack = pokemon.atk_stat
            defense = target.def_stat
          else
            attack = pokemon.sp_atk_stat
            defense = target.sp_def_stat
          end

          damage = Formulas.damage_formula(
            attack: attack,
            defense: defense,
            lvl: pokemon.lvl,
            power: move.power
          )

          target.update!(hp: target.hp - damage)
          BattleEngine.logger.info("#{target.pokemon_template.name} took #{damage} damage")
        end
      end
    end
  end
end

# implementar specs para acción de daño
