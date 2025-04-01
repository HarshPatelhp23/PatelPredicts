# frozen_string_literal: true

class MatchesController < ApplicationController
  # IPL LOGIC
  # def current_week_schedule
  #   @current_week_start_date = [Date.current.beginning_of_week, Auction::CT_FIRST_WEEK_DATE.to_date].max
  #   if params[:move_to_next_week] == 'true'
  #     move_to_next_week(@current_week_start_date)
  #     return nil
  #   end
  #   @pool_users = default_auction.users
  #   # @current_week_end_date = Date.current.end_of_week
  #   @current_week_end_date = @current_week_start_date.end_of_week
  #   @current_week_matches = MatchSchedule.where(match_date: @current_week_start_date..@current_week_end_date).order(match_date: :asc)
  #   @auction  = default_auction
  # end

  #FOR TESTING PURPOSE ONLY
  def current_week_schedule
    @current_week_start_date = [Date.current.beginning_of_week, Auction::IPL_FIRST_WEEK_DATE.to_date].max
    if params[:move_to_next_week] == 'true'
      move_to_next_week(@current_week_start_date)
      return nil
    end
    @pool_users = default_auction.users
    # @current_week_end_date = Date.current.end_of_week
    @current_week_end_date = @current_week_start_date.end_of_week
    @current_week_matches = MatchSchedule.where(match_date: @current_week_start_date..@current_week_end_date).order(match_date: :asc)
    @auction  = default_auction
  end

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

  # def current_week_schedule
  #   if params[:move_to_next_week] == 'true'
  #     move_to_next_week
  #     return nil
  #   end

  #   @pool_users = User.pool_users(current_user)
  #   @current_week_start_date = [Date.current.beginning_of_week, Auction::T20_WC_FIRST_WEEK_DATE.to_date].max
  #   @current_week_end_date = Date.current.end_of_week
  #   set_match_dates
  # end

  def match_players
    team_name = []
    @selected_user = User.find(params[:user_id])
    @selected_teams = params[:match_name].split(' vs ').select { |team| team_name << match_country_code[team] }
    if team_name.compact_blank.blank?
      t1,t2 = params[:match_name].split(' vs ')
      u_t1 = match_country_code[t1].upcase
      u_t2 = match_country_code[t2].upcase
      team_name = [ut1,ut2]
    end 
    # team_name = @selected_teams if team_name.include?(nil) # for super-8
    @user_team = @selected_user.teams.where(auction: default_auction)&.first
    if @selected_user.weekly_user_teams.count > 1
      current_week_team = @selected_user.weekly_user_teams
                                         .where(team: @user_team)
                                         .where("week_end_date >= ?", Date.current)&.first || @selected_user.weekly_user_teams.where(team: @user_team)&.first
      current_week_player_ids = current_week_team.playing11
    else
      current_week_team = @selected_user&.weekly_user_teams&.where(team: @user_team)&.last
      current_week_player_ids = current_week_team&.playing11
    end
    @auction  = default_auction
    team_name = team_name.map(&:upcase)
    @selected_user_team = @selected_user.teams.where(auction: @auction)
    @rank = @auction.teams.order(grand_total: :desc).index(@selected_user_team).present? ? @auction.teams.order(grand_total: :desc).index(@selected_user_team) + 1 : '-'
    @players = @selected_user_team.first.players.where(id: current_week_player_ids, team_name: team_name)
  end

  def point_system; end

  private

  def default_auction
    params[:auction_id].present? ? Auction.find(params[:auction_id]) : current_user.auctions.last
  end

  def default_team
    default_team = current_user.teams.where(auction: default_auction).first
    default_team
  end

  def match_country_code
    {
      'Afghanistan' => 'AFG',
      'Australia' => 'AUS',
      'Bangladesh' => 'BAN',
      'England' => 'ENG',
      'India' => 'IND',
      'New Zealand' => 'NZ',
      'Pakistan' => 'PAK',
      'South Africa' => 'RSA',
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
      'Uganda' => 'UG',
      'Chennai Super Kings' => 'csk',
      'Rajasthan Royals' => 'rr',
      'Kolkata Knight Riders' => 'kkr',
      'Sunrisers Hyderabad' => 'srh',
      'Royal Challengers Bengaluru' => 'rcb',
      'Delhi Capitals' => 'dc',
      'Punjab Kings' => 'pbks',
      'Mumbai Indians' => 'mi',
      'Gujarat Titans' => 'gt',
      'Lucknow Super Giants' => 'lsg'
    }
  end

  def move_to_next_week(start_date)
    @pool_users = default_auction.users
    @current_week_start_date = start_date.next_week(:monday)
    @current_week_end_date = @current_week_start_date.end_of_week
    @current_week_matches = MatchSchedule.where(match_date: @current_week_start_date..@current_week_end_date).order(match_date: :asc)
    # set_match_dates
  end

  def set_match_dates
    @first_half_end_date = @current_week_start_date + 3.days
    @second_half_start_date = @first_half_end_date + 1.day
    @second_half_end_date = @second_half_start_date + 2.days
    @first_half_matches = MatchSchedule.where(match_date: @current_week_start_date..@first_half_end_date).order(match_date: :asc)
    @second_half_matches = MatchSchedule.where(match_date: @second_half_start_date..@second_half_end_date).order(match_date: :asc)
  end

  def next_week_monday
    if Date.current.wday.zero?
      Date.current + 1.day
    else
      Date.current + ((1 - Date.current.wday) % 7) + 7
    end
  end
end
