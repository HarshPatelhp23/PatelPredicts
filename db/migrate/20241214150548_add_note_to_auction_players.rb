class AddNoteToAuctionPlayers < ActiveRecord::Migration[7.0]
  def change
    add_column :auction_players, :note, :text
  end
end
