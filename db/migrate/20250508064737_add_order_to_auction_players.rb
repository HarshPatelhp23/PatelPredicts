class AddOrderToAuctionPlayers < ActiveRecord::Migration[7.0]
  def change
    add_column :auction_players, :order, :integer
    add_column :users, :franchise_name, :string
  end
end
