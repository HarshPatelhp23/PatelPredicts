class Svl::Season < ApplicationRecord
	# self.table_name = "svl_seasons"

  has_many :teams,   class_name: "Svl::Team",   foreign_key: :season_id, dependent: :destroy
  has_many :matches, class_name: "Svl::Match",  foreign_key: :season_id, dependent: :destroy

  validates :name, presence: true

  def points_table
    teams.order(points: :desc, set_diff: :desc, points_diff: :desc)
  end
end
