# frozen_string_literal: true

class Player < ApplicationRecord
  has_many :teams
  has_and_belongs_to_many :battles, join_table: "battle_players"

  validates :name, presence: true, uniqueness: true

  def info_event_payload
    {
      player: {
        id:,
        name:,
        teams: [],
        battle_history: {
          victories: battles.select { |b| b.winner?(self) }.count,
          defeats: battles.select { |b| !b.winner?(self) }.count,
          history: battles.last(10).map { |b| b.winner?(self) ? "V" : "D" }
        }
      },
      battles: battle_info_event_payload
    }
  end

  def battle_info_event_payload
    battles.running.map do |battle|
      { 
        id: battle.id, 
        opponent: battle_player_names(battle.players)
      } 
    end
  end

  private

  def battle_player_names(players)
    # TODO: Ajustar a equipos
    # {name: "player_x", team: "A"} -> nombre del jugador y su equipo
    players.filter { |p| p.id != id }.map(&:name).join(", ")
  end
end
