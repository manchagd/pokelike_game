# frozen_string_literal: true

class Weather < ApplicationRecord
  belongs_to :field

  validates :name, presence: true, uniqueness: true
  validates :harm, numericality: true, allow_nil: true
end
