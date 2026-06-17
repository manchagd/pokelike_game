# frozen_string_literal: true

class AdjustPositionsToUsePokemonSnapshots < ActiveRecord::Migration[7.2]
  def change
    remove_foreign_key :positions, :pokemons
    remove_column :positions, :pokemon_id, :bigint
    add_reference :positions, :pokemon_snapshot, null: false, foreign_key: { to_table: :pokemon_battle_snapshots }
  end
end
