class CreateSvlMatches < ActiveRecord::Migration[7.0]
  def change
    create_table :svl_matches do |t|

      t.references :season,       null: false, foreign_key: { to_table: :svl_seasons }
      t.references :winning_team, null: true,  foreign_key: { to_table: :svl_teams }
      t.references :losing_team,  null: true,  foreign_key: { to_table: :svl_teams }
      t.integer :winning_team_points, null: false, default: 0
      t.integer :losing_team_points,  null: false, default: 0
      t.integer :winning_team_sets,   null: false, default: 0
      t.integer :losing_team_sets,    null: false, default: 0
      t.date    :played_on

      t.timestamps
    end
  end
end
