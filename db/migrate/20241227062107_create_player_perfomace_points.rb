class CreatePlayerPerfomacePoints < ActiveRecord::Migration[7.0]
  def change
    create_table :player_perfomace_points do |t|
      t.references :player
      t.string :match

      #batting fields
      t.integer :in_playing11, default: 0
      t.integer :runs, default: 0
      t.integer :balls_faced, default: 0
      t.integer :fours, default: 0
      t.integer :sixes, default: 0
      t.integer :strike_rate, default: 0
      t.string :out_desc, default: ''
      
      #bowling fields
      t.integer :overs_bowled, default: 0
      t.integer :wickets, default: 0
      t.integer :maidens, default: 0
      t.float :eco, default: 0

      #fielding fields
      t.integer :catches
      t.integer :run_outs
      t.integer :stumping

      #points fields
      t.boolean :duck, default: false
      t.integer :'bonus_30', default: 0
      t.integer :'bonus_50', default: 0
      t.integer :'bonus_100', default: 0
      t.integer :lbw_bonus, default: 0
      t.integer :bowled_bonus, default: 0
      t.integer :'bonus_3w', default: 0
      t.integer :'bonus_4w', default: 0
      t.integer :'bonus_5w', default: 0
      t.integer :'eco_bonus', default: 0
      t.integer :'catch_bonus', default: 0

      #for back-tracking purpose
      t.jsonb :overall_data, null: false, default: '{}'

      t.timestamps
    end
  end
end
