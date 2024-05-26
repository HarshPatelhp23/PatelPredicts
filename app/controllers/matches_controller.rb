# frozen_string_literal: true

class MatchesController < ApplicationController
  def current_week_schedule
    @pool_users = User.where(auction_id: current_user.auction_id)
    @current_week_start_date = Date.current.beginning_of_week
    @current_week_end_date = Date.current.end_of_week
    @current_week_matches = MatchSchedule.where(match_date: @current_week_start_date..@current_week_end_date).order(match_date: :asc)
  end

  def match_players
    @selected_user = User.find(params[:user_id])
    @selected_teams = params[:match_name].split(' vs ')
    current_week_player_ids = @selected_user.weekly_user_teams.order(created_at: :desc).first.playing11
    @players = @selected_user.team.players.where(id: current_week_player_ids, team_name: @selected_teams)
  end
end
