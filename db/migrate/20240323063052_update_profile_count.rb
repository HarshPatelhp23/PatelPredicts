class UpdateProfileCount < ActiveRecord::Migration[7.0]
  def up
    add_column :users, :update_profile_count, :integer, default: 0, if_not_exists: true

    # Check if the column exists before updating
    unless column_exists?(:users, :update_profile_count)
      User.update_all(update_profile_count: 0)
    end
  end

  def down
    remove_column :users, :update_profile_count
  end
end
