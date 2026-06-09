# frozen_string_literal: true

class Player < ApplicationRecord
  has_many :teams

  validates :name, presence: true, uniqueness: true


  def info_event_payload
    {
      player: {
        id:,
        name:,
        teams: [],
        battle_history: {
          victories: 0,
          defeats: 0,
          history: []
      }
      },
      battles: []
    }
  end
end
