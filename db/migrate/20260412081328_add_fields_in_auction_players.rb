class AddFieldsInAuctionPlayers < ActiveRecord::Migration[7.0]
  def change
    add_column :auction_players, :fifties, :string
    add_column :auction_players, :hundreds, :string
    add_column :auction_players, :wickets, :string
    add_column :auction_players, :eco, :float

    add_reference :spl_fantasy_teams, :captain, foreign_key: { to_table: :auction_players }, type: :bigint
    add_reference :spl_fantasy_teams, :vice_captain, foreign_key: { to_table: :auction_players }, type: :bigint


    add_column :auction_players, :points, :float
  end
end
