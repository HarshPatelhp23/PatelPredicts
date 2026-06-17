class Svl::MatchesController < ApplicationController
  before_action :authenticate_spl_user!

  def index
    @seasons = Svl::Season.order(created_at: :desc)
 
    # Default to the most recent season
    if params[:season_id].present?
      @selected_season = @seasons.find_by(id: params[:season_id])
    end
    @selected_season ||= @seasons.first
 
    if @selected_season
      @matches = @selected_season.matches
                   .includes(:winning_team, :losing_team, :match_sets)
                   .order(played_on: :desc, id: :desc)
 
      # Optional: filter by match_type
      if params[:match_type].present? && params[:match_type] != "all"
        @matches = @matches.where(match_type: params[:match_type])
      end
 
      # Group by date for the timeline view
      @matches_by_date = @matches.group_by { |m| m.played_on || :tbd }
    else
      @matches         = []
      @matches_by_date = {}
    end
 
    # Stats for the selected season
    if @selected_season
      all = @selected_season.matches.includes(:winning_team, :losing_team)
      @total_matches   = all.count
      @league_matches  = all.where(match_type: :league).count
      @ko_matches      = all.where.not(match_type: :league).count
      @total_sets      = Svl::MatchSet.joins(:match)
                           .where(svl_matches: { season_id: @selected_season.id })
                           .count
    end
  end

  def score_match
    @season = Svl::Season.order(created_at: :desc).first
    @teams  = @season ? @season.teams.order(:name) : Svl::Team.none
  end

  def save_match
    season     = Svl::Season.find(params[:season_id])
    winning_id = params[:winning_team_id].to_i
    losing_id  = params[:losing_team_id].to_i
    sets_data  = params[:sets] || []
    match_type = params[:match_type].presence || "league"

    ActiveRecord::Base.transaction do
      match = Svl::Match.create!(
        season:          season,
        winning_team_id: winning_id,
        losing_team_id:  losing_id,
        match_type:      match_type,
        played_on:       Date.today
      )
      sets_data.each_with_index do |set, i|
        Svl::MatchSet.create!(
          match:              match,
          set_number:         i + 1,
          winning_team_score: set[:winning_score].to_i,
          losing_team_score:  set[:losing_score].to_i
        )
      end
    end
    render json: { success: true }
  rescue => e
    render json: { success: false, error: e.message }, status: :unprocessable_entity
  end
end
