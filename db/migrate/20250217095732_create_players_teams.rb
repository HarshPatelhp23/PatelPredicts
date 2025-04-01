class CreatePlayersTeams < ActiveRecord::Migration[7.0]
  def change
    create_table :players_teams do |t|
      t.references :player, null: false, foreign_key: true
      t.references :team, null: false, foreign_key: true
      t.float :sold_price

      t.timestamps
    end
  end
end
