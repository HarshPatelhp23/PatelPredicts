class AddTimeToMatchSchedules < ActiveRecord::Migration[7.0]
  def change
    add_column :match_schedules, :time, :string, if_not_exists: true
  end
end
