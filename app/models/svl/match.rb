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
  after_destroy :update_team_stats

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

  def update_team_stats
    return unless league?

    winning_team&.recalculate_stats!
    losing_team&.recalculate_stats!
  end
end
