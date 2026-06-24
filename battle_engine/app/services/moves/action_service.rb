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
# pokemon = PokemonBattleSnapshot.find(555)
# target = PokemonBattleSnapshot.find(554)
# move = Move.find(173)

# Services::Moves::ActionService.call(pokemon, target, move)
#
# Agregar rspec para hacer pruebas unitarias a todos estos ataques
# y no tener que depender de datos en consola,
# incluira factory bot y crear trais adecuados
