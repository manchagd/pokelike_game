# frozen_string_literal: true

class CreateTrainers < ActiveRecord::Migration[7.1]
  def change
    create_table :trainers do |t|
      t.string :name, null: false
      t.integer :level, default: 1, null: false
      t.timestamps
    end
  end
end
