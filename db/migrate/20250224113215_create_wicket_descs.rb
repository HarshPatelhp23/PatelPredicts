class CreateWicketDescs < ActiveRecord::Migration[7.0]
  def change
    create_table :wicket_descs do |t|
      t.string :desc, array: true, default:[]
      t.string :match_name
      t.timestamps
    end
  end
end
