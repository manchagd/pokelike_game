# frozen_string_literal: true

class Battle < ApplicationRecord
  has_one :field
  has_one :winner, class_name: "Player"
end
