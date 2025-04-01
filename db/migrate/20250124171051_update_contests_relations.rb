class UpdateContestsRelations < ActiveRecord::Migration[7.0]
  def change
    remove_column :users, :auction_id, if_exists: true

    add_column :teams, :auction_id, :bigint, foreign_key: true
  end
end
