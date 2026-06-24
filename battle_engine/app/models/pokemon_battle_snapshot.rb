# frozen_string_literal: true

class PokemonBattleSnapshot < ApplicationRecord
  belongs_to :pokemon
  belongs_to :battle
  belongs_to :player

  before_create :set_default_stat_stages

  def lvl
    pokemon.lvl
  end

  def atk_stat
    pokemon.atk_stat * Formulas.stage_multiplier(stat_stages[:atk_stage])
  end

  def def_stat
    pokemon.def_stat * Formulas.stage_multiplier(stat_stages[:def_stage])
  end

  def sp_atk_stat
    pokemon.sp_atk_stat * Formulas.stage_multiplier(stat_stages[:sp_atk_stage])
  end

  def sp_def_stat
    pokemon.sp_def_stat * Formulas.stage_multiplier(stat_stages[:sp_def_stage])
  end

  def spd_stat
    pokemon.spd_stat * Formulas.stage_multiplier(stat_stages[:spd_stage])
  end

  def accuracy_stage
    stat_stages[:accuracy_stage]
  end

  def evasion_stage
    stat_stages[:evasion_stage]
  end

  private

  def set_default_stat_stages
    self.stat_stages ||= {
      atk_stage: 0,
      def_stage: 0,
      sp_atk_stage: 0,
      sp_def_stage: 0,
      spd_stage: 0,
      crit_stage: 0,
      accuracy_stage: 0,
      evasion_stage: 0
    }
  end

  # =========================================================================
  # DOCUMENTACIÓN DE CAMPOS JSONB (Estructura y posibles valores)
  # =========================================================================

  # 1. :status_condition
  # Contiene el estado alterado del Pokémon en la batalla (tanto volátiles como no volátiles).
  # Valores posibles:
  # {
  #   "non_volatile": "Paralysis" | "Burn" | "Freeze" | "Poison" | "Sleep" | "BadlyPoisoned" | null,
  #   "volatile": ["Confusion", "Flinch", "Infatuation", "Taunt", "Yawn", ...] # Array de estados volátiles activos
  # }

  # 2. :stat_stages
  # Representa los modificadores de estadísticas en combate.
  # Los valores numéricos van desde -6 hasta +6 (siendo 0 el valor base).
  # Valores posibles:
  # {
  #   "atk_stage": Integer,      # Modificador de Ataque
  #   "def_stage": Integer,      # Modificador de Defensa
  #   "sp_atk_stage": Integer,   # Modificador de Ataque Especial
  #   "sp_def_stage": Integer,   # Modificador de Defensa Especial
  #   "spd_stage": Integer,      # Modificador de Velocidad
  #   "accuracy_stage": Integer, # Modificador de Precisión
  #   "evasion_stage": Integer,  # Modificador de Evasión
  #   "critical_stage": Integer  # Modificador de Ratio de Golpe Crítico (usualmente 0 a +3 o +4)
  # }

  # 3. :turn_afflictions
  # Guarda los eventos y aflicciones temporales específicos que ocurren durante el turno en curso.
  # Valores posibles:
  # {
  #   "damage_taken_this_turn": Integer, # Cantidad de daño recibido en el turno actual
  #   "harmed?": Boolean,                # true si el Pokémon ha recibido daño directo en este turno
  #   "touched?": Boolean,               # true si ha recibido un ataque de contacto
  #   "flitched?": Boolean               # true si ha retrocedido en este turno
  # }

  # 4. :locked_condition
  # Indica si el Pokémon está bloqueado/comprometido en una acción que requiere múltiples turnos.
  # Valores posibles:
  # {
  #   "is_locked_into_move?": Boolean,  # true si está usando un movimiento de varios turnos (ej. Outrage, Rollout)
  #   "is_charging?": Boolean,          # true si está cargando un movimiento (ej. Solar Beam, Fly en el primer turno)
  #   "is_invulnerable?": Boolean       # true si está en fase semi-invulnerable (ej. bajo tierra por Dig, en el aire por Fly)
  # }

  # 5. :attack_log
  # Historial o registro de movimientos y acciones de ataque ejecutados por el Pokémon en la batalla actual.
  # Valores posibles:
  # [
  #   {
  #     "turn": Integer,         # Número de turno en el que se realizó el ataque
  #     "move_name": String,     # Nombre del movimiento ejecutado (ej. "Tackle")
  #     "target_pokemon_id": Integer, # ID del objetivo (si aplica)
  #     "result": String         # Resultado (ej. "hit", "missed", "immune", "critical")
  #   }
  # ]
end
