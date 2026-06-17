# frozen_string_literal: true

class AddBattleToPokemonBattleSnapshots < ActiveRecord::Migration[7.2]
  def change
    add_reference :pokemon_battle_snapshots, :battle, null: false, foreign_key: true
  end
end
