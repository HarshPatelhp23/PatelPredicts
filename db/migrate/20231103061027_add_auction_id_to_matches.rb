class AddAuctionIdToMatches < ActiveRecord::Migration[7.0]
  def change
    add_column :matches, :auction_id, :bigint, if_not_exists: true
  end
end
