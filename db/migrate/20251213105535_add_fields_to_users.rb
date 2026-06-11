class AddFieldsToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :phone_number, :string
    add_column :users, :security_question, :string
    add_column :users, :security_answer, :string
    add_column :users, :favorite_format, :string
    add_column :users, :bio, :string
    add_column :users, :notifications_enabled, :boolean, default: false
  end
end
