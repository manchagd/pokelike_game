# frozen_string_literal: true

class AddPokeapiIdToMovesAndPokemonTemplates < ActiveRecord::Migration[7.2]
  def change
    add_column :moves, :pokeapi_id, :integer
    add_index  :moves, :pokeapi_id, unique: true

    add_column :pokemon_templates, :pokeapi_id, :integer
    add_index  :pokemon_templates, :pokeapi_id, unique: true
  end
end
