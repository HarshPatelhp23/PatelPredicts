# frozen_string_literal: true

class AddConfirmableToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :confirmation_token, :string, if_not_exists: true
    add_column :users, :confirmed_at, :datetime, if_not_exists: true
    add_column :users, :confirmation_sent_at, :datetime, if_not_exists: true
    add_column :users, :unconfirmed_email, :string, if_not_exists: true
  end
end
