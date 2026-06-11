class CreateRemoveFieldsFromSplUsers < ActiveRecord::Migration[7.0]
  def change
    remove_column :spl_users, :otp
    remove_column :spl_users, :category
  end
end
