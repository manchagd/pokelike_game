# frozen_string_literal: true

class CreateTeamPokemons < ActiveRecord::Migration[7.2]
  def change
    create_table :team_pokemons do |t|
      t.references :team, null: false, foreign_key: true
      t.references :pokemon, null: false, foreign_key: true
      
      t.timestamps
    end
  end
end
