class AddBenchPointsFields < ActiveRecord::Migration[7.0]
  def change
    add_column :matches, :bench_points, :float, default: 0
    add_column :match_points, :total_bench_points, :float, default: 0
    add_column :players_teams, :bench_points, :float, default: 0
  end
end
