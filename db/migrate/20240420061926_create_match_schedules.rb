class CreateMatchSchedules < ActiveRecord::Migration[7.0]
  def change
    create_table :match_schedules do |t|
      t.integer :match_number
      t.string :match_name
      t.string :stadium
      t.date :match_date

      t.timestamps
    end
  end
end
