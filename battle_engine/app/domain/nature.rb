# frozen_string_literal: true

class Nature
  LIST = [
    HARDY = 'Hardy',
    LONELY = 'Lonely',
    BRAVE = 'Brave',
    ADAMANT = 'Adamant',
    NAUGHTY = 'Naughty',
    BOLD = 'Bold',
    DOCILE = 'Docile',
    RELAXED = 'Relaxed',
    IMPISH = 'Impish',
    LAX = 'Lax',
    TIMID = 'Timid',
    HASTY = 'Hasty',
    SERIOUS = 'Serious',
    JOLLY = 'Jolly',
    NAIVE = 'Naive',
    MODEST = 'Modest',
    MILD = 'Mild',
    QUIET = 'Quiet',
    BASHFUL = 'Bashful',
    RASH = 'Rash',
    CALM = 'Calm',
    GENTLE = 'Gentle',
    SASSY = 'Sassy',
    CAREFUL = 'Careful',
    QUIRKY = 'Quirky'
  ].freeze

  MODIFIERS = {
    LONELY => { atk: 1.1, def: 0.9 },
    BRAVE => { atk: 1.1, spd: 0.9 },
    ADAMANT => { atk: 1.1, sp_atk: 0.9 },
    NAUGHTY => { atk: 1.1, sp_def: 0.9 },
    BOLD => { def: 1.1, atk: 0.9 },
    RELAXED => { def: 1.1, spd: 0.9 },
    IMPISH => { def: 1.1, sp_atk: 0.9 },
    LAX => { def: 1.1, sp_def: 0.9 },
    TIMID => { spd: 1.1, atk: 0.9 },
    HASTY => { spd: 1.1, def: 0.9 },
    JOLLY => { spd: 1.1, sp_atk: 0.9 },
    NAIVE => { spd: 1.1, sp_def: 0.9 },
    MODEST => { sp_atk: 1.1, atk: 0.9 },
    MILD => { sp_atk: 1.1, def: 0.9 },
    QUIET => { sp_atk: 1.1, spd: 0.9 },
    RASH => { sp_atk: 1.1, sp_def: 0.9 },
    CALM => { sp_def: 1.1, atk: 0.9 },
    GENTLE => { sp_def: 1.1, def: 0.9 },
    SASSY => { sp_def: 1.1, spd: 0.9 },
    CAREFUL => { sp_def: 1.1, sp_atk: 0.9 }
  }.freeze

  def self.modifier_for(nature_name, stat_key)
    mods = MODIFIERS[nature_name]
    return 1.0 if mods.nil?

    mods[stat_key.to_sym] || 1.0
  end
end
