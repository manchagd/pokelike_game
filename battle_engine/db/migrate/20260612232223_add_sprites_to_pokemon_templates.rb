# frozen_string_literal: true

class AddSpritesToPokemonTemplates < ActiveRecord::Migration[7.2]
  def change
    add_column :pokemon_templates, :front_sprite, :string
    add_column :pokemon_templates, :back_sprite,  :string
  end
end
