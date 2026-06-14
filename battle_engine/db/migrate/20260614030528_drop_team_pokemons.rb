# frozen_string_literal: true

class DropTeamPokemons < ActiveRecord::Migration[7.2]
  def change
    drop_table :team_pokemons do |t|
      t.bigint :team_id, null: false
      t.bigint :pokemon_id, null: false
      t.timestamps
    end
  end
end
