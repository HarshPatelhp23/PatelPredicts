class CreateSvlSeasons < ActiveRecord::Migration[7.0]
  def change
    create_table :svl_seasons do |t|
      t.string :name, null: false
      t.date   :start_date
      t.date   :end_date

      t.timestamps
    end
  end
end
