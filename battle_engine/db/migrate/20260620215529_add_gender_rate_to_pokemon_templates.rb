# frozen_string_literal: true

class AddGenderRateToPokemonTemplates < ActiveRecord::Migration[7.2]
  def change
    add_column :pokemon_templates, :gender_rate, :integer
  end
end
