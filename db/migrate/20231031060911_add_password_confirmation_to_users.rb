class AddPasswordConfirmationToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :password_confirmation, :string, if_not_exists: true
    add_column :users, :otp, :string, if_not_exists: true
  end
end
