class AddWeekToWeeklyUserTeams < ActiveRecord::Migration[7.0]
  def change
    add_column :weekly_user_teams, :week, :integer, default: 0
  end
end
