# frozen_string_literal: true

class CreatePokemonBattleSnapshots < ActiveRecord::Migration[7.2]
  def change
    create_table :pokemon_battle_snapshots do |t|
      t.references :pokemon, null: false, foreign_key: true
      t.integer :hp, null: false
      t.jsonb :status_condition, null: false, default: {}
      t.jsonb :stat_stages, null: false, default: {}
      t.jsonb :turn_afflictions, null: false, default: {}
      t.jsonb :locked_condition, null: false, default: {}
      t.jsonb :attack_log, null: false, default: {}

      t.timestamps
    end
  end
end
