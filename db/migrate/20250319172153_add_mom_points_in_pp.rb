class AddMomPointsInPp < ActiveRecord::Migration[7.0]
  def change
    add_column :player_perfomace_points ,:is_mom, :boolean, default: false
    add_column :player_perfomace_points, :bonus_mom, :integer, default: 0
  end
end
