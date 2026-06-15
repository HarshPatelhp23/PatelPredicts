class Svl::Match < ApplicationRecord
  belongs_to :season,       class_name: "Svl::Season"
  belongs_to :winning_team, class_name: "Svl::Team", optional: true
  belongs_to :losing_team,  class_name: "Svl::Team", optional: true

  has_many :match_sets, class_name: "Svl::MatchSet",
           foreign_key: :match_id, dependent: :destroy

  enum match_type: {
    league:    0,
    semi_final: 1,
    eliminator: 2,
    final:     3
  }
  after_save    :update_team_stats
  before_destroy :delete_team_stats
  after_commit :send_match_summary_mail, on: [:create]

  def recalculate_points!
    sets = match_sets.reload

    # Points = sum of all scores across sets
    self.winning_team_points = sets.sum(:winning_team_score)
    self.losing_team_points  = sets.sum(:losing_team_score)

    # Sets WON — count how many individual sets each side won
    self.winning_team_sets = sets.count { |s| s.winning_team_score > s.losing_team_score }
    self.losing_team_sets  = sets.count { |s| s.losing_team_score > s.winning_team_score }

    update_columns(
      winning_team_points: winning_team_points,
      losing_team_points:  losing_team_points,
      winning_team_sets:   winning_team_sets,
      losing_team_sets:    losing_team_sets
    )

    if league?
      winning_team&.recalculate_stats!
      losing_team&.recalculate_stats!
    end
  end

  private

  def send_match_summary_mail
    MatchMailer.match_summary(self).deliver_now
  end

  def update_team_stats
    return unless league?

    winning_team&.recalculate_stats!
    losing_team&.recalculate_stats!
  end

  def delete_team_stats
    winning_team.update_columns(no_of_matches_played: 0, no_of_matches_won: 0, no_of_matches_lost: 0, points_diff: 0, set_diff: 0, points:0)
  end
end
