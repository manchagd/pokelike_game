# frozen_string_literal: true

class Field < ApplicationRecord
  has_many :hazards, :positions
  has_one :weather
  belongs_to :battle
end
