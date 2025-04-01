class AddPointsToPlayersTeams < ActiveRecord::Migration[7.0]
  def change
    add_column :players_teams, :points, :integer, default: 0, if_not_exists: true
    add_column :players_teams, :bench, :boolean, default: false
    add_reference :player_perfomace_points, :team, foreign_key: true,  if_not_exists: true
    remove_column :players, :points, :integer, if_exists: true
  end
end
