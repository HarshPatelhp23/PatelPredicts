class Svl::MatchesController < ApplicationController
  before_action :authenticate_spl_user!

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
