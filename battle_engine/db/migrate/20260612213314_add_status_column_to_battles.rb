# frozen_string_literal: true

class AddStatusColumnToBattles < ActiveRecord::Migration[7.2]
  def change
    add_column :battles, :status, :string, null: false, default: "not_started"
  end
end
