# frozen_string_literal: true

class CreateBids < ActiveRecord::Migration[7.0]
  def change
    create_table :bids do |t|
      t.integer :bid_amount
      t.references :player, null: false
      t.bigint :user_id, null: true

      t.timestamps
    end
  end
end
