class AddPurseFieldsToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :remaining_purse, :integer, default: 50000000
    add_column :users, :total_purse, :integer, default: 50000000
    add_column :users, :captain, :boolean, default: false
  end
end
