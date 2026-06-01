# frozen_string_literal: true

class CreatePokemons < ActiveRecord::Migration[7.2]
  def change
    create_table :pokemons do |t|
      t.references :pokemon_template, null: false, foreign_key: true
      t.references :player, null: false, foreign_key: true
      t.string :nickname
      t.string :gender
      t.string :nature, null: false
      t.decimal :weight, precision: 8, scale: 2, null: false
      t.jsonb :ivs, null: false, default: {}
      t.jsonb :evs, null: false, default: {}
      t.string :attacks, array: true, default: [], null: false
      t.integer :lvl, null: false
      t.jsonb :metadata, null: false, default: {}
      t.string :teratype 

      t.timestamps
    end
  end
end
