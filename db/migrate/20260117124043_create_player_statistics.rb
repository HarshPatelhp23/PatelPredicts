class CreatePlayerStatistics < ActiveRecord::Migration[7.0]
   def change
    create_table :player_statistics do |t|
      t.references :player, null: false, foreign_key: true
      
      # Batting Statistics
      t.integer :test_matches, default: 0
      t.integer :test_innings, default: 0
      t.integer :test_runs, default: 0
      t.integer :test_balls, default: 0
      t.string :test_highest
      t.decimal :test_average, precision: 10, scale: 2
      t.decimal :test_strike_rate, precision: 10, scale: 2
      t.integer :test_not_out, default: 0
      t.integer :test_fours, default: 0
      t.integer :test_sixes, default: 0
      t.integer :test_ducks, default: 0
      t.integer :test_fifties, default: 0
      t.integer :test_hundreds, default: 0
      t.integer :test_double_hundreds, default: 0
      
      t.integer :odi_matches, default: 0
      t.integer :odi_innings, default: 0
      t.integer :odi_runs, default: 0
      t.integer :odi_balls, default: 0
      t.string :odi_highest
      t.decimal :odi_average, precision: 10, scale: 2
      t.decimal :odi_strike_rate, precision: 10, scale: 2
      t.integer :odi_not_out, default: 0
      t.integer :odi_fours, default: 0
      t.integer :odi_sixes, default: 0
      t.integer :odi_ducks, default: 0
      t.integer :odi_fifties, default: 0
      t.integer :odi_hundreds, default: 0
      t.integer :odi_double_hundreds, default: 0
      
      t.integer :t20_matches, default: 0
      t.integer :t20_innings, default: 0
      t.integer :t20_runs, default: 0
      t.integer :t20_balls, default: 0
      t.string :t20_highest
      t.decimal :t20_average, precision: 10, scale: 2
      t.decimal :t20_strike_rate, precision: 10, scale: 2
      t.integer :t20_not_out, default: 0
      t.integer :t20_fours, default: 0
      t.integer :t20_sixes, default: 0
      t.integer :t20_ducks, default: 0
      t.integer :t20_fifties, default: 0
      t.integer :t20_hundreds, default: 0
      t.integer :t20_double_hundreds, default: 0
      
      t.integer :ipl_matches, default: 0
      t.integer :ipl_innings, default: 0
      t.integer :ipl_runs, default: 0
      t.integer :ipl_balls, default: 0
      t.string :ipl_highest
      t.decimal :ipl_average, precision: 10, scale: 2
      t.decimal :ipl_strike_rate, precision: 10, scale: 2
      t.integer :ipl_not_out, default: 0
      t.integer :ipl_fours, default: 0
      t.integer :ipl_sixes, default: 0
      t.integer :ipl_ducks, default: 0
      t.integer :ipl_fifties, default: 0
      t.integer :ipl_hundreds, default: 0
      t.integer :ipl_double_hundreds, default: 0
      
      # Bowling Statistics
      t.integer :test_bowling_innings, default: 0
      t.integer :test_bowling_balls, default: 0
      t.integer :test_bowling_runs, default: 0
      t.integer :test_bowling_maidens, default: 0
      t.integer :test_bowling_wickets, default: 0
      t.decimal :test_bowling_average, precision: 10, scale: 2
      t.decimal :test_bowling_economy, precision: 10, scale: 2
      t.decimal :test_bowling_strike_rate, precision: 10, scale: 2
      t.string :test_best_bowling_innings
      t.string :test_best_bowling_match
      t.integer :test_four_wickets, default: 0
      t.integer :test_five_wickets, default: 0
      t.integer :test_ten_wickets, default: 0
      
      t.integer :odi_bowling_innings, default: 0
      t.integer :odi_bowling_balls, default: 0
      t.integer :odi_bowling_runs, default: 0
      t.integer :odi_bowling_maidens, default: 0
      t.integer :odi_bowling_wickets, default: 0
      t.decimal :odi_bowling_average, precision: 10, scale: 2
      t.decimal :odi_bowling_economy, precision: 10, scale: 2
      t.decimal :odi_bowling_strike_rate, precision: 10, scale: 2
      t.string :odi_best_bowling_innings
      t.string :odi_best_bowling_match
      t.integer :odi_four_wickets, default: 0
      t.integer :odi_five_wickets, default: 0
      t.integer :odi_ten_wickets, default: 0
      
      t.integer :t20_bowling_innings, default: 0
      t.integer :t20_bowling_balls, default: 0
      t.integer :t20_bowling_runs, default: 0
      t.integer :t20_bowling_maidens, default: 0
      t.integer :t20_bowling_wickets, default: 0
      t.decimal :t20_bowling_average, precision: 10, scale: 2
      t.decimal :t20_bowling_economy, precision: 10, scale: 2
      t.decimal :t20_bowling_strike_rate, precision: 10, scale: 2
      t.string :t20_best_bowling_innings
      t.string :t20_best_bowling_match
      t.integer :t20_four_wickets, default: 0
      t.integer :t20_five_wickets, default: 0
      t.integer :t20_ten_wickets, default: 0
      
      t.integer :ipl_bowling_innings, default: 0
      t.integer :ipl_bowling_balls, default: 0
      t.integer :ipl_bowling_runs, default: 0
      t.integer :ipl_bowling_maidens, default: 0
      t.integer :ipl_bowling_wickets, default: 0
      t.decimal :ipl_bowling_average, precision: 10, scale: 2
      t.decimal :ipl_bowling_economy, precision: 10, scale: 2
      t.decimal :ipl_bowling_strike_rate, precision: 10, scale: 2
      t.string :ipl_best_bowling_innings
      t.string :ipl_best_bowling_match
      t.integer :ipl_four_wickets, default: 0
      t.integer :ipl_five_wickets, default: 0
      t.integer :ipl_ten_wickets, default: 0
      
      t.string :cricbuzz_player_id
      t.datetime :last_synced_at

      t.timestamps
    end

    add_index :player_statistics, :cricbuzz_player_id, unique: true
  end
end
