class CreateSplUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :spl_users do |t|
      t.string :name
      t.string :otp
      t.integer :category

      t.timestamps
    end
  end
end
