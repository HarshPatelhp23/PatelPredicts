class AddBenchInPlayers < ActiveRecord::Migration[7.0]
  def change
    add_column :players, :bench, :boolean, default: true, if_not_exists: true
  end
end
