# frozen_string_literal: true

class Field < ApplicationRecord
  has_many :positions
  has_one :battle, inverse_of: :field
end
