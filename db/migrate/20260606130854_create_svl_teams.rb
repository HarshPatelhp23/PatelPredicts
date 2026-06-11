class CreateSvlTeams < ActiveRecord::Migration[7.0]
  def change
    create_table :svl_teams do |t|
      t.references :season, null: false, foreign_key: { to_table: :svl_seasons }
      t.string  :name,                  null: false
      t.integer :no_of_matches_played,  null: false, default: 0
      t.integer :no_of_matches_won,     null: false, default: 0
      t.integer :no_of_matches_lost,    null: false, default: 0
      t.integer :points_diff,           null: false, default: 0
      t.integer :set_diff,              null: false, default: 0
      t.integer :points,                null: false, default: 0

      t.timestamps
    end
  end
end
