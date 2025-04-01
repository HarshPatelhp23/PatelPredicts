class AddGrandTotalToTeams < ActiveRecord::Migration[7.0]
  def change
    add_column :teams, :grand_total, :integer, default: 0
  end
end
