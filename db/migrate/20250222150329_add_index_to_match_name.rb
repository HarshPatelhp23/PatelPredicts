class AddIndexToMatchName < ActiveRecord::Migration[7.0]
  def change
    add_index :matches, :match_name
    add_index :match_points, :match_name
  end
end
