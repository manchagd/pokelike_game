# frozen_string_literal: true

class AddPlayerToPokemonBattleSnapshots < ActiveRecord::Migration[7.2]
  def up
    add_reference :pokemon_battle_snapshots, :player, foreign_key: true, null: true

    # Backfill existing records
    execute <<~SQL
      UPDATE pokemon_battle_snapshots
      SET player_id = teams.player_id
      FROM pokemons
      INNER JOIN teams ON teams.id = pokemons.team_id
      WHERE pokemons.id = pokemon_battle_snapshots.pokemon_id
    SQL

    change_column_null :pokemon_battle_snapshots, :player_id, false
  end

  def down
    remove_reference :pokemon_battle_snapshots, :player
  end
end
