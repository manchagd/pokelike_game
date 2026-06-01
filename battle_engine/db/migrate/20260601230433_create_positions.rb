# frozen_string_literal: true

class CreatePositions < ActiveRecord::Migration[7.2]
  def change
    remove_column :fields, :positions, :jsonb

    create_table :positions do |t|
      t.integer :group, null: false
      t.string :side
      t.references :pokemon, null: true, foreign_key: true
      t.references :field, null: false, foreign_key: true
      
      t.timestamps
    end
  end
end
