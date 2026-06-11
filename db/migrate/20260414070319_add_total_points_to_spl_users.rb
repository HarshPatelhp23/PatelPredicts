class AddTotalPointsToSplUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :spl_users, :total_points, :integer, default: 0
    add_column :auction_players, :category, :integer
  end
end
