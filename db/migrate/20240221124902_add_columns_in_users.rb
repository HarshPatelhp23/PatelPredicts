class AddColumnsInUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :penalty_points, :integer, default: 0, if_not_exists: true
    add_column :users, :final_total_points, :integer, default: 0, if_not_exists: true
  end
end
