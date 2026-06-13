# frozen_string_literal: true

class BattlePlayer < ApplicationRecord
  belongs_to :player
  belongs_to :battle

  validate :valid_group?

  before_validation :circle_team_assigner, on: :create

  private

  def circle_team_assigner
    self.group = battle.battle_players.count.odd? ? 'A' : 'B'
  end

  def valid_group?
    errors.add(:group, 'must be valid') unless %w[A B].include?(group)
  end
end
