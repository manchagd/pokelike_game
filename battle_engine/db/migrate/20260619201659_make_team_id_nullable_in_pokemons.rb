# frozen_string_literal: true

class MakeTeamIdNullableInPokemons < ActiveRecord::Migration[7.2]
  def change
    change_column_null :pokemons, :team_id, true
  end
end
