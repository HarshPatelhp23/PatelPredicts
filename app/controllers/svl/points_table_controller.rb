class Svl::PointsTableController < ApplicationController
  def index
    @season = Svl::Season.order(created_at: :desc).first
    @teams  = @season ? @season.points_table.to_a : []

    @all_matches = @season ? @season.matches
                               .includes(:winning_team, :losing_team, :match_sets)
                               .order(played_on: :desc)
                           : Svl::Match.none

    # League matches only for the points table section
    @league_matches = @all_matches.league

    # Knockout bracket matches
    @knockout_matches = @all_matches.where(match_type: [:qualifier, :eliminator, :final])
                                    .order(match_type: :asc, played_on: :asc)

    if params[:team_id].present?
      @filter_team = @teams.find { |t| t.id == params[:team_id].to_i }
      @matches = @league_matches.where(
        "winning_team_id = ? OR losing_team_id = ?",
        params[:team_id], params[:team_id]
      )
    else
      @filter_team = nil
      @matches = @league_matches.limit(10)
    end
  end
end
