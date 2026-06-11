class RemoveUniqueIndexAuctionPlayerIdFromAuctionRooms < ActiveRecord::Migration[7.0]
  def change
    remove_index :auction_rooms, name: "index_auction_rooms_on_auction_player_id"
  end
end
