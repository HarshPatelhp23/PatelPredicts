class AddCricbuzzImageIdToPlayers < ActiveRecord::Migration[7.0]
  def change
    add_column :players, :cricbuzz_image_id, :integer
  end
end
