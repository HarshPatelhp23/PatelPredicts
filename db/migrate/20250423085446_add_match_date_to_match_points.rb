class AddMatchDateToMatchPoints < ActiveRecord::Migration[7.0]
  def change
    add_column :match_points, :match_date, :date
  end
end
