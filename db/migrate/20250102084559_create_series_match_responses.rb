class CreateSeriesMatchResponses < ActiveRecord::Migration[7.0]
  def change
    create_table :series_match_responses do |t|
      t.jsonb :match_data, default: '{}'
      t.jsonb :series_res, default: '{}'
      t.jsonb :recent_match_res,  default: '{}'
      t.timestamps
    end
  end
end
