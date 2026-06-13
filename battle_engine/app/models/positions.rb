# frozen_string_literal: true

class Positions < ApplicationRecord
  belongs_to :field
  has_one :pokemon

  validates :group, presence: true, numericality: { only_integer: true }
  validates :side, inclusion: { in: %w[A B] }, allow_nil: true
end
