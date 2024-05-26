class CreateAuctions < ActiveRecord::Migration[7.0]
  def change
    create_table :auctions do |t|
      t.string :name
      t.date :starts_at
      t.integer :status
      t.integer :teams_count
      t.bigint :admin_user_id

      t.timestamps
    end
  end
end
