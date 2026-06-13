# frozen_string_literal: true

class CreateTeams < ActiveRecord::Migration[7.2]
  def change
    create_table :teams do |t|
      t.string :name, null: false
      t.references :player, null: false, foreign_key: true

      t.timestamps
    end
  end
end
