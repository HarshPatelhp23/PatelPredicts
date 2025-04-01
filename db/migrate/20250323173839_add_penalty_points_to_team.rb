class AddPenaltyPointsToTeam < ActiveRecord::Migration[7.0]
  def change
    add_column :teams, :penalty_points, :integer, default: 0
  end
end
