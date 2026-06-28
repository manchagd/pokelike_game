# frozen_string_literal: true

class BattleLog < ApplicationRecord
  belongs_to :battle

  validates :message, presence: true
end
