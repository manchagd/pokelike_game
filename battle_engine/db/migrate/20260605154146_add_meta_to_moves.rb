# frozen_string_literal: true

class AddMetaToMoves < ActiveRecord::Migration[7.2]
  def change
    add_column :moves, :meta, :jsonb, default: {}
  end
end
