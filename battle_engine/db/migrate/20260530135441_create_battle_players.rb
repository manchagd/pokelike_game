# frozen_string_literal: true

class CreateBattlePlayers < ActiveRecord::Migration[7.2]
  def change
    create_table :battle_players do |t|
      t.references :battle, null: false, foreign_key: true
      t.references :player, null: false, foreign_key: true
      
      t.timestamps
    end
  end
end
