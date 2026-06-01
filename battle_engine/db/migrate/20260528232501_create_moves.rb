# frozen_string_literal: true

class CreateMoves < ActiveRecord::Migration[7.2]
  def change
    create_table :moves do |t|
      t.string :name, null: false
      t.string :type, null: false
      t.string :secondary_type
      t.string :category, null: false
      t.integer :pp, null: false
      t.integer :power
      t.integer :priority, null: false, default: 0
      t.integer :accuracy, null: false, default: 100
      t.timestamps
    end
    
    add_index :moves, :name, unique: true
  end
end
