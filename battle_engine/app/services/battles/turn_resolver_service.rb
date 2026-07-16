# frozen_string_literal: true

module Services
  module Battles
    class TurnResolverService
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

        actions_by_priority = parse_actions(actions)

        resolve_actions(actions_by_priority)
      end

      private

      def priority_queue
        {
          8 => [],
          7 => [],
          6 => [],
          5 => [],
          4 => [],
          3 => [],
          2 => [],
          1 => [],
          0 => [],
          -1 => [],
          -2 => [],
          -3 => [],
          -4 => [],
          -5 => [],
          -6 => [],
          -7 => []
        }
      end

      def parse_actions(actions)
        actions.each_with_object(priority_queue) do |action, priority_queue|
          case action
          in { action: 'attack', player_id:, attack_id:, pokemon_id:, targets: }
            priority = move_priority(attack_id)

            parse_action(priority_queue, priority, incomming_attack(player_id:, pokemon_id:, attack_id:, targets:))
          in { action: 'switch', player_id:, pokemon_id: }
            parse_action(priority_queue, switch_priority, incomming_switch(player_id:, pokemon_id:))
          in { action: 'attack_switch', player_id:, attack_id:, pokemon_id:, targets:, pokemon_switched_id: }
            priority = move_priority(attack_id)

            parse_action(priority_queue, priority, incomming_attack(player_id:, pokemon_id:, attack_id:, targets:))
            parse_action(priority_queue, priority, incomming_switch(player_id:, pokemon_id: pokemon_switched_id))
          end
        end
      end

      def move_priority(attack_id)
        attack = Attack.find(attack_id)
        attack.move.priority
      end

      def switch_priority
        6
      end

      def parse_action(priority_queue, priority, action)
        priority_queue[priority] << action
      end

      def incomming_attack(player_id:, pokemon_id:, attack_id:, targets:)
        { player_id:, pokemon_id:, attack_id:, targets: }
      end

      def incomming_attack_switch(player_id:, pokemon_id:, attack_id:, targets:, pokemon_switched_id:)
        { player_id:, pokemon_id:, attack_id:, targets:, pokemon_switched_id: }
      end

      def incomming_switch(player_id:, pokemon_id:)
        { player_id:, pokemon_id: }
      end

      def resolve_actions(actions_by_priority)
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
