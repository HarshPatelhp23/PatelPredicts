class CreateAuctionPlayers < ActiveRecord::Migration[7.0]
  def change
    create_table :auction_players do |t|
      t.string :name
      t.integer :batting
      t.integer :bowling
      t.boolean :sold, default: false
      t.integer :base_price
      t.timestamps
    end
  end
end
