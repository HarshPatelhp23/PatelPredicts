class AddCricbuzzPlayerIdToPlayers < ActiveRecord::Migration[7.0]
  def change
    add_column :players, :cricbuzz_player_id, :integer
  end
end
