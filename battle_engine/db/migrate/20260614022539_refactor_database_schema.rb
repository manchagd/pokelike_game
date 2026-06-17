# frozen_string_literal: true

class RefactorDatabaseSchema < ActiveRecord::Migration[7.2]
  def change
    # 1. Add weight to pokemon_templates
    add_column :pokemon_templates, :weight, :decimal, precision: 8, scale: 2

    # 2. Remove attacks array from pokemons
    remove_column :pokemons, :attacks, :string, array: true, default: [], null: false

    # 3. Create attacks join table
    create_table :attacks do |t|
      t.references :pokemon, null: false, foreign_key: true
      t.references :move, null: false, foreign_key: true

      t.timestamps
    end
    add_index :attacks, %i[pokemon_id move_id], unique: true
  end
end
