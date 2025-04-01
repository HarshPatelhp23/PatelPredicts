class AddStrikeRateBonusToPp < ActiveRecord::Migration[7.0]
  def change
    add_column :player_perfomace_points, :strike_rate_bonus, :integer, default: 0
  end
end
