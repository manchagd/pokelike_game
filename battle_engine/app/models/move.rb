# frozen_string_literal: true

class Move < ApplicationRecord
  self.inheritance_column = nil

  has_and_belongs_to_many :pokemon_templates, join_table: :pokemon_template_moves

  # Validar category
end
