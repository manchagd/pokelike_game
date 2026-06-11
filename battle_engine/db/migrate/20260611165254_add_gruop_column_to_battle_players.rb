# frozen_string_literal: true

class AddGruopColumnToBattlePlayers < ActiveRecord::Migration[7.2]
  def change
    add_column :battle_players, :group, :string, null: false
  end
end
