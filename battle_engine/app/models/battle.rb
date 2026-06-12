# frozen_string_literal: true
require 'securerandom'

class Battle < ApplicationRecord
  has_one :field
  has_one :winner, class_name: "Player"
  has_and_belongs_to_many :players
  
  before_create :set_external_id

  # Logica para identificar o status da battle
  # Logica de equipos, y jugadores
  scope :running, -> { all }

  def winner?(player)
    winner_id == player.id
  end
  
  private 

  def set_external_id
    self.external_id = loop do
      first_chain = SecureRandom.alphanumeric(3).upcase
      second_chain = SecureRandom.alphanumeric(3).upcase
      chain = "#{first_chain}-#{second_chain}"
      
      break chain unless Battle.exists?(external_id: chain)
    end
  end
end