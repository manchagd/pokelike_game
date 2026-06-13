# frozen_string_literal: true

class CreateFields < ActiveRecord::Migration[7.2]
  def change
    create_table :fields do |t|
      t.jsonb :positions, null: false, default: {}
      t.references :weather, foreign_key: true
      t.references :hazard, foreign_key: true

      t.timestamps
    end
  end
end
