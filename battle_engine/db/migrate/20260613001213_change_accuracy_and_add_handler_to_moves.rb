# frozen_string_literal: true

class ChangeAccuracyAndAddHandlerToMoves < ActiveRecord::Migration[7.2]
  def change
    change_column :moves, :accuracy, :integer, null: true, default: nil
    add_column    :moves, :handler,  :string
  end
end
