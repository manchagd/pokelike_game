# frozen_string_literal: true

class CreateWeathers < ActiveRecord::Migration[7.2]
  def change
    create_table :weathers do |t|
      t.string :name, null: false
      t.integer :duration, null: false, default: 5
      t.integer :harm
      t.jsonb :type_modifiers, default: {}
      
      t.timestamps
    end

    add_index :weathers, :name, unique: true
  end
end
