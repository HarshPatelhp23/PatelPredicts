class CreateSplOtps < ActiveRecord::Migration[7.0]
  def change
    create_table :spl_otps do |t|
      t.string :email, null: false
      t.string :otp_code, null: false
      t.datetime :otp_sent_at
      t.boolean :verified, default: false
      t.timestamps
    end
    
    add_index :spl_otps, :email
    add_index :spl_otps, [:email, :otp_code]
  end
end
