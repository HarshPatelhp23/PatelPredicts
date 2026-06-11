class AddReplacementOfToPlayers < ActiveRecord::Migration[7.0]
  def change
    add_column :players, :replacement_of, :string
  end
end
