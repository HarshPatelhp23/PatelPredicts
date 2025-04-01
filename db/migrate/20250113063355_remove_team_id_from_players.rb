class RemoveTeamIdFromPlayers < ActiveRecord::Migration[7.0]
  def change
    remove_column :players, :team_id
  end
end
