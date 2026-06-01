# frozen_string_literal: true

class CreatePokemonTemplates < ActiveRecord::Migration[7.2]
  def change
    create_table :pokemon_templates do |t|
      t.string :name, null: false
      t.string :types, array: true, default: []
      t.jsonb :stats, null: false, default: {}

      t.timestamps
    end
    
    add_index :pokemon_templates, :name, unique: true
  end
end
