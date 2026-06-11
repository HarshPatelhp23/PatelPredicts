class ChangeOversBowledToFloat < ActiveRecord::Migration[7.0]
  def change
    change_column :player_perfomace_points, :overs_bowled, :float, default: 0
  end
end
