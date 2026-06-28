# frozen_string_literal: true

class CreateBattleLogs < ActiveRecord::Migration[7.2]
  def change
    create_table :battle_logs do |t|
      t.references :battle, null: false, foreign_key: true
      t.text :message, null: false

      t.timestamps
    end
  end
end
