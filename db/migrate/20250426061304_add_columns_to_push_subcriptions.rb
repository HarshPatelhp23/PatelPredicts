class AddColumnsToPushSubcriptions < ActiveRecord::Migration[7.0]
  def change
    add_column :push_subscriptions, :device_type, :string, default: 'desktop'
  end
end
