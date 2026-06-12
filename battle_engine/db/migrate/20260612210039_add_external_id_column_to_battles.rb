# frozen_string_literal: true

class AddExternalIdColumnToBattles < ActiveRecord::Migration[7.2]
  def change
    add_column :battles, :external_id, :string
    add_index :battles, :external_id, unique: true
  end
end
