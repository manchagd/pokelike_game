# frozen_string_literal: true

class AddStatsToPokemons < ActiveRecord::Migration[7.2]
  def up
    add_column :pokemons, :stats, :jsonb, null: false, default: {}

    # Reset ActiveRecord column cache to read new column
    Pokemon.reset_column_information

    # Backfill existing pokemons
    Pokemon.find_each(&:save!)
  end

  def down
    remove_column :pokemons, :stats
  end
end
