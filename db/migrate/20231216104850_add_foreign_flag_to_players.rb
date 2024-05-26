class AddForeignFlagToPlayers < ActiveRecord::Migration[7.0]
  def change
    add_column :players, :foreigner, :boolean , default: false, if_not_exists: true
    rename_column :players, :nation, :team_name
  end
end
