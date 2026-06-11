class AddCityToMatchSchedules < ActiveRecord::Migration[7.0]
  def change
    add_column :match_schedules, :city, :string
  end
end
