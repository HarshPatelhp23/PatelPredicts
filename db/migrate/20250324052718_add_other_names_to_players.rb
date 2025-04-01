class AddOtherNamesToPlayers < ActiveRecord::Migration[7.0]
  def change
    add_column :players, :other_names, :string, array: true, default: []
  end
end
