class AddFieldsToPlayers < ActiveRecord::Migration[7.0]
  def change
    add_column :players, :batting_style, :string
    add_column :players, :bowling_style, :string
  end
end
