class CreateSvlMatchSets < ActiveRecord::Migration[7.0]
  def change
    create_table :svl_match_sets do |t|
      t.references :match, null: false, foreign_key: { to_table: :svl_matches }
      t.integer :set_number,          null: false
      t.integer :winning_team_score,  null: false, default: 0
      t.integer :losing_team_score,   null: false, default: 0

      t.timestamps
    end
    add_index :svl_match_sets, [:match_id, :set_number], unique: true
  end
end
