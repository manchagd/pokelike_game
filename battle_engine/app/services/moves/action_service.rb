# frozen_string_literal: true

module Services
  module Moves
    class ActionService
      def call(pokemon, target, move)
        if move.category == Move::PHYSICAL
          attack = pokemon.atk_stat
          defense = target.def_stat
        else
          attack = pokemon.sp_atk_stat
          defense = target.sp_def_stat
        end

        move.handler_service.call(attack, defense, pokemon, move)
      end
    end
  end
end
# pokemon = PokemonBattleSnapshot.find(555)
# target = PokemonBattleSnapshot.find(554)
# move = Move.find(173)

# Services::Moves::ActionService.call(pokemon, target, move)
