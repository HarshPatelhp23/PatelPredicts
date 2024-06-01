# frozen_string_literal: true

class MatchesController < ApplicationController
  # IPL LOGIC
  # def current_week_schedule
  #   @pool_users = User.where(auction_id: current_user.auction_id)
  #   @current_week_start_date = Date.current.beginning_of_week
  #   @current_week_end_date = Date.current.end_of_week
  #   @current_week_matches = MatchSchedule.where(match_date: @current_week_start_date..@current_week_end_date).order(match_date: :asc)
  # end

  # WC LOGIC
  # def current_week_schedule
  #   @pool_users = User.where(auction_id: current_user.auction_id)
  #   @current_week_start_date = Date.current.beginning_of_week - 1.day #also first_week_start_date
  #   @current_week_end_date = Date.current.end_of_week
  #   @first_half_end_date = @current_week_start_date + 4.days
  #   @second_half_start_date = @current_week_start_date + 1.day
  #   @second_half_end_date = @second_half_start_date + 2.day
  #   @current_week_matches = MatchSchedule.where(match_date: @current_week_start_date..@current_week_end_date).order(match_date: :asc)
  # end

  def current_week_schedule
    @pool_users = User.where(auction_id: current_user.auction_id)
    @current_week_start_date = if Date.current.beginning_of_week < Auction::T20_WC_FIRST_WEEK_DATE.to_date
                                 Auction::T20_WC_FIRST_WEEK_DATE.to_date # also first_week_start_date
                               else
                                 Date.current.beginning_of_week - 1.day
                               end
    @current_week_end_date = Date.current.end_of_week
    @first_half_end_date = @current_week_start_date + 4.days
    @second_half_start_date = @first_half_end_date + 1.day
    @second_half_end_date = @second_half_start_date + 2.days
    @first_half_matches = MatchSchedule.where(match_date: @current_week_start_date..@first_half_end_date).order(match_date: :asc)
    @second_half_matches = MatchSchedule.where(match_date: @second_half_start_date..@second_half_end_date).order(match_date: :asc)
  end

  def match_players
    team_name = []
    @selected_user = User.find(params[:user_id])
    @selected_teams = params[:match_name].split(' vs ').select { |team| team_name << match_country_code[team] }
    current_week_player_ids = @selected_user.weekly_user_teams.order(created_at: :desc).first.playing11
    @players = @selected_user.team.players.where(id: current_week_player_ids, team_name:)
  end

  private

  def match_country_code
    {
      'Afghanistan' => 'AFG',
      'Australia' => 'AUS',
      'Bangladesh' => 'BANG',
      'England' => 'ENG',
      'India' => 'IND',
      'New Zealand' => 'NZ',
      'Pakistan' => 'PAK',
      'South Africa' => 'SA',
      'Sri Lanka' => 'SL',
      'West Indies' => 'WI',
      'USA' => 'USA',
      'Canada' => 'CA',
      'Ireland' => 'IRE',
      'Namibia' => 'NAM',
      'Nepal' => 'NEP',
      'Netherlands' => 'NETH',
      'Oman' => 'OMN',
      'Papua New Guinea' => 'PNG',
      'Scotland' => 'SCOT',
      'Uganda' => 'UG'
    }
  end
end
