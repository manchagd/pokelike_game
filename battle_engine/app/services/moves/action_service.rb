# frozen_string_literal: true

module Services
  module Moves
    class ActionService
      def self.call(pokemon, target, move)
        if target.status_condition[:invulnerable]
          BattleEngine.logger.info("#{target.pokemon.pokemon_template.name} is invulnerable")
          return
        end

        final_accuracy = Formulas.accuracy_formula(pokemon, target, move)
        if final_accuracy < rand(1..100)
          BattleEngine.logger.info("#{pokemon.pokemon.pokemon_template.name} missed")
          return
        end

        move.handler_service.call(pokemon, target, move)
      end
    end
  end
end
