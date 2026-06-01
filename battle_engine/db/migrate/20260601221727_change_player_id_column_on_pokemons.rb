# frozen_string_literal: true

class ChangePlayerIdColumnOnPokemons < ActiveRecord::Migration[7.2]
  def change
    remove_reference :pokemons, :player, foreign_key: true, index: true
    add_reference :pokemons, :team, foreign_key: true, null: false
  end
end
