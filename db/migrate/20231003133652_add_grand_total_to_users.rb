class AddGrandTotalToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :grand_total, :integer, default: 0, if_not_exists: true
  end
end
