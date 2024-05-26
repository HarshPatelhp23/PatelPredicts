class CreateMatches < ActiveRecord::Migration[7.0]
  def change
    create_table :matches do |t|
      t.string :match_name
      t.bigint :player_id
      t.bigint :team_id
      t.integer :points

      t.timestamps
    end
  end
end
