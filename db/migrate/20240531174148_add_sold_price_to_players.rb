class AddSoldPriceToPlayers < ActiveRecord::Migration[7.0]
  def change
    add_column :players, :sold_price, :string, if_not_exists: true
  end
end
