class AddOtpVerifiedToUsers < ActiveRecord::Migration[7.0]
  def up
    add_column :users, :otp_verified, :boolean, default: false, if_not_exists: true
    User.update_all(otp_verified: true)
  end

  def down
    remove_column :users, :otp_verified, :boolean, if_exists: true
  end
end
