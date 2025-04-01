class AddTeamIdToWeeklyUserTeams < ActiveRecord::Migration[7.0]
  def change
     add_reference :weekly_user_teams, :team, foreign_key: true
  end
end
