# frozen_string_literal: true

class CreateBattles < ActiveRecord::Migration[7.2]
  def change
    create_table :battles do |t|
      t.string :battle_type, null: false, default: "single"
      t.references :field, null: false, foreign_key: true
      t.references :winner, foreign_key: { to_table: :players }

      t.timestamps
    end
  end
end
