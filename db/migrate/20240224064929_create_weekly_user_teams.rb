class CreateWeeklyUserTeams < ActiveRecord::Migration[7.0]
  def change
    create_table :weekly_user_teams do |t|
      t.references :user, null: false
      t.date :week_start_date
      t.date :week_end_date
      t.integer :playing11, array: true, default:[]
      t.integer :bench, array: true, default:[]

      t.timestamps
    end
  end
end
