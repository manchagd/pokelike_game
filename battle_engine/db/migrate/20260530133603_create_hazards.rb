# frozen_string_literal: true

class CreateHazards < ActiveRecord::Migration[7.2]
  def change
    create_table :hazards do |t|
      t.string :name, null: false
      t.jsonb :effect, null: false, default: {}
      
      t.timestamps
    end

    add_index :hazards, :name, unique: true
  end
end
