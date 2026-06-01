# frozen_string_literal: true

class Hazard < ApplicationRecord
  belongs_to :field

  validates :name, presence: true, uniqueness: true
end