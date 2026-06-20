# frozen_string_literal: true

module Services
  module Moves
    module Handlers
      class Damage
        def self.call(attack, defense, pokemon, move)
          Formulas.damage_formula(
            attack: attack,
            defense: defense,
            lvl: pokemon.lvl,
            power: move.power
          )
        end
      end
    end
  end
end
