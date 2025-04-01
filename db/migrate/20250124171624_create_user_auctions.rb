class CreateUserAuctions < ActiveRecord::Migration[7.0]
  def change
    create_table :user_auctions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :auction, null: false, foreign_key: true

      t.timestamps
    end
  end
end
