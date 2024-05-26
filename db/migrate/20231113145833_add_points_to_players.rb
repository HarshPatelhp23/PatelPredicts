class AddPointsToPlayers < ActiveRecord::Migration[7.0]
  def change
    add_column :players, :points, :integer, default: 0, if_not_exists: true
  end
end
