class AddNationToPlayers < ActiveRecord::Migration[7.0]
  def change
    add_column :players, :nation, :string, if_not_exists: true
  end
end
