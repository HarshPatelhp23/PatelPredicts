class Svl::MatchSet < ApplicationRecord
	belongs_to :match, class_name: "Svl::Match"

  validates :set_number, presence: true,
            uniqueness: { scope: :match_id },
            numericality: { greater_than: 0 }
  validates :winning_team_score, :losing_team_score,
            numericality: { greater_than_or_equal_to: 0 }

  after_save    :recalculate_match_points
  after_destroy :recalculate_match_points

  private

  def recalculate_match_points
    match.recalculate_points!
  end
end
