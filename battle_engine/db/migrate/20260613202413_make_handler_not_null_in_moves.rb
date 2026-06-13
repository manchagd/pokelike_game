# frozen_string_literal: true

class MakeHandlerNotNullInMoves < ActiveRecord::Migration[7.2]
  def change
    change_column_null :moves, :handler, false, "Unique"
  end
end
