class Svl::Team < ApplicationRecord
  belongs_to :season, class_name: "Svl::Season"

  has_many :won_matches,
           class_name:  "Svl::Match",
           foreign_key: :winning_team_id,
           dependent:   :nullify

  has_many :lost_matches,
           class_name:  "Svl::Match",
           foreign_key: :losing_team_id,
           dependent:   :nullify

  validates :name, presence: true, uniqueness: { scope: :season_id }

  def recalculate_stats!
    won  = won_matches.reload
    lost = lost_matches.reload

    self.no_of_matches_won    = won.count
    self.no_of_matches_lost   = lost.count
    self.no_of_matches_played = no_of_matches_won + no_of_matches_lost

    # Points scored by this team minus points scored against them
    pts_for     = won.sum(:winning_team_points) + lost.sum(:losing_team_points)
    pts_against = won.sum(:losing_team_points)  + lost.sum(:winning_team_points)
    self.points_diff = pts_for - pts_against

    # Set diff = (sets this team won) - (sets this team lost) across ALL matches
    # In won_matches: this team won `winning_team_sets`, opponent won `losing_team_sets`
    # In lost_matches: this team won `losing_team_sets`, opponent won `winning_team_sets`
    # in simple terms t1 vs t2 (match name) then t1 is winning_team and t2 is lossing team
    sets_this_team_won  = won.sum(:winning_team_sets) + lost.sum(:losing_team_sets)
    sets_this_team_lost = won.sum(:losing_team_sets)  + lost.sum(:winning_team_sets)
    self.set_diff = sets_this_team_won - sets_this_team_lost

    self.points = no_of_matches_won * 2

    save!
  end
end