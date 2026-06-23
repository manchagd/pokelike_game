# frozen_string_literal: true

module Services
  module Battles
    module Turns
      class ResolverService
        # Prioridad	Acciones en el turno
        # +8	      Mensaje de activación de garra rápida, mano rápida y baya Chiri
        # +7	      Ninguno
        # +6        Carga de coraza trampa, pico cañón y puño certero, uso de objetos, cambio de Pokémon, huir de un combate
        # +5	      Refuerzo
        # +4	      Aguante, barrera espinosa, búnker, detección, escudo real, llama protectora, obstrucción, protección, telatrampa
        # +3	      Anticipo, sorpresa, vastaguardia, palma rauda
        # +2	      Amago, cambio de banda, escaramuza, polvo ira, señuelo, velocidad extrema
        # +1	      Acua jet, ataque rápido, esquirla helada, fitoimpulso(con hierba), golpe bajo, ojitos tiernos, onda vacío, puño bala, puño jet, relámpago súbito, roca veloz, shuriken de agua, sombra vil, ultrapuño
        # 0	        Resto de movimientos, fitoimpulso(sin hierba)
        # -1	      Ninguno
        # -2	      Ninguno
        # -3	      Coraza trampa, pico cañón, puño certero
        # -4	      Alud, desquite
        # -5	      Contraataque, manto espejo
        # -6	      Cola dragón, llave giro, torbellino, rugido, teletransporte
        # -7	      Espacio raro

        def call(actions:)
          BattleEngine.logger.info("[TurnResolverService] Resolving #{actions.size} action(s): #{actions}")

          actions_by_priority = assign_actions_by_priority(actions)

          resolve_actions_in_order(actions_by_priority)
        end

        private

        def actions_by_priority
          {
            8 => [],
            6 => [],
            5 => [],
            4 => [],
            3 => [],
            2 => [],
            1 => [],
            0 => [],
            -3 => [],
            -4 => [],
            -5 => [],
            -6 => [],
            -7 => []
          }
        end

        # Groups actions by their priority value, then orders each group by speed.
        # Returns a flat array of actions in resolution order.
        def assign_actions_by_priority(actions)
          # actions: [{action: "attack", player_id: 1, move_id: 801, pokemon_id: nil, targets: ["stakataka"]}, {action: "switch", player_id: 3, move_id: nil, pokemon_id: 584, targets: nil}]}
          actions.each_with_object(actions_by_priority) do |action, actions_by_priority|
            case action
            in { action: 'attack', player_id:, move_id:, pokemon_id:, targets: }
              priority = move_priority(move_id)

              actions_by_priority[priority] << incomming_attack(player_id:, pokemon_id:, move_id:, targets:)
            in { action: 'switch', player_id:, pokemon_id: }
              priority = switch_priority

              actions_by_priority[priority] << incomming_switch(player_id:, pokemon_id:)
            end
          end
        end

        def move_priority(move_id)
          move = Move.find(move_id)

          move.priority
        end

        def switch_priority
          6
        end

        def incomming_attack(player_id:, pokemon_id:, move_id:, targets:)
          { player_id:, pokemon_id:, move_id:, targets: }
        end

        def incomming_switch(player_id:, pokemon_id:)
          { player_id:, pokemon_id: }
        end

        def resolve_actions_in_order(actions_by_priority)
          actions_by_priority.compact_blank.each do |priority, actions|
            BattleEngine.logger.info("[TurnResolverService] Resolving #{priority} priority: #{actions}")
          end
        end

        # Within the same priority tier, higher speed goes first.
        # Ties are broken randomly (coin flip), as in the mainline games.
        def sort_by_speed(actions)
          # MOCK
          actions.sort_by { |a| [-a.fetch(:speed, 0), rand] }
        end
      end
    end
  end
end
