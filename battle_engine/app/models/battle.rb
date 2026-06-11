# frozen_string_literal: true

class Battle < ApplicationRecord
  has_one :field
  has_one :winner, class_name: "Player"
  has_and_belongs_to_many :players

  # Logica para identificar o status da battle
  # Logica de equipos, y jugadores
  scope :running, -> { all }

  def winner?(player)
    winner_id == player.id
  end
end
