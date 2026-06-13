# frozen_string_literal: true

class BattlePlayer < ApplicationRecord
  belongs_to :player
  belongs_to :battle

  validates valid_group?

  private

  def valid_group?
    errors.add(:group, 'must be valid') unless %w[A B].include?(group)
  end
end
