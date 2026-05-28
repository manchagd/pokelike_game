# frozen_string_literal: true

class CreatePokemonTemplateMoves < ActiveRecord::Migration[7.2]
  def change
    create_table :pokemon_template_moves do |t|
      t.references :pokemon_template, null: false, foreign_key: true
      t.references :move, null: false, foreign_key: true

      t.timestamps
    end
  end
end
