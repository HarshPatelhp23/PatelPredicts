class CreateFantasyTeamsAuctionPlayers < ActiveRecord::Migration[7.0]
  def change
    create_join_table :spl_fantasy_teams, :auction_players, 
      table_name: :fantasy_teams_auction_players,
      column_options: { null: false, foreign_key: true, type: :bigint } do |t|
      
      t.index [:spl_fantasy_team_id, :auction_player_id], unique: true, name: 'index_fantasy_teams_auction_players_unique'
      t.index [:auction_player_id, :spl_fantasy_team_id], name: 'index_auction_players_fantasy_teams_unique'
      
      t.timestamps
    end
  end
end
