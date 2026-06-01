# frozen_string_literal: true

class AddTurnColumnToBattles < ActiveRecord::Migration[7.2]
  def change
    add_column :battles, :turn, :integer, null: false, default: 0
  end
end
