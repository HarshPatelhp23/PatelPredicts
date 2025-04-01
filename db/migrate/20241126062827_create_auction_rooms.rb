class CreateAuctionRooms < ActiveRecord::Migration[7.0]
  def change
    create_table :auction_rooms do |t|

      t.string :player_name
      t.float :amount
      t.integer :amount_unit
      t.references :user
      t.belongs_to :auction_player, index: { unique: true }, foreign_key: true

      t.timestamps
    end
  end
end
