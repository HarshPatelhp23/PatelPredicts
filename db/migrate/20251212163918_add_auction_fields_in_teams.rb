class AddAuctionFieldsInTeams < ActiveRecord::Migration[7.0]
  def change
    add_column :teams, :total_purse, :float
    add_column :teams, :remaining_purse, :float
  end
end
