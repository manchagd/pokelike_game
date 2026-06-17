# frozen_string_literal: true

require 'securerandom'

class Battle < ApplicationRecord
  belongs_to :field, inverse_of: :battle
  belongs_to :winner, class_name: 'Player', optional: true
  has_many :battle_players, dependent: :destroy
  has_many :players, through: :battle_players
  has_many :pokemon_battle_snapshots, dependent: :destroy

  before_create :set_external_id

  enum :status, { not_started: 'not_started', in_progress: 'in_progress', finished: 'finished' }

  scope :running, -> { where.not(status: :finished) }

  # Logica de equipos, y jugadores

  def winner?(player)
    winner_id == player.id
  end

  private

  def set_external_id
    self.external_id = loop do
      first_chain = SecureRandom.alphanumeric(3)
      second_chain = SecureRandom.alphanumeric(3)
      chain = "#{first_chain}-#{second_chain}"

      break chain unless Battle.exists?(external_id: chain)
    end
  end
end
