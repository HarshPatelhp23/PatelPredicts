class CreateMatchPoints < ActiveRecord::Migration[7.0]
  def change
    create_table :match_points do |t|

      t.string :match_name
      t.bigint :team_id
      t.integer :total_points

      t.timestamps
    end
  end
end
