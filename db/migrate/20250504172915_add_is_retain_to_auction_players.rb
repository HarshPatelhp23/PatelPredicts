class AddIsRetainToAuctionPlayers < ActiveRecord::Migration[7.0]
  def change
    add_column :auction_players, :is_retain, :boolean, default: false
    add_column :auction_players, :trophies_won, :integer, default: 0
  end
end
