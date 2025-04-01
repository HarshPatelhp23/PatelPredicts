class AddTeamChangesToWeeklyTeams < ActiveRecord::Migration[7.0]
  def change
    add_column :weekly_user_teams, :team_changes, :jsonb, default: '{}'
  end
end
