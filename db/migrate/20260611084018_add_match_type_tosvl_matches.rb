class AddMatchTypeTosvlMatches < ActiveRecord::Migration[7.0]
  def change
    add_column :svl_matches, :match_type, :integer, default: 0, null: false
  end
end
