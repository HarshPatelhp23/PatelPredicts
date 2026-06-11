class CreateSplFantasyTeams < ActiveRecord::Migration[7.0]
  def change
    create_table :spl_fantasy_teams do |t|
      t.string :team_name
      t.references :spl_user, null: false, foreign_key: true
      t.integer :playing11, array: true, default:[]

      t.timestamps
    end
  end
end
