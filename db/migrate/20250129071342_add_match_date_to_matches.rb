class AddMatchDateToMatches < ActiveRecord::Migration[7.0]
  def change
    add_column :matches, :match_date, :date, if_not_exists: true
  end
end
