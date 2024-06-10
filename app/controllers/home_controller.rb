# frozen_string_literal: true

class HomeController < ApplicationController
  # skip_before_action :verify_authenticity_token, only: :after_login
  before_action :authenticate_user!, except: %i[verify_otp process_otp resend_otp welcome after_login]

  def welcome
    current_user ? (redirect_to after_login_path) : (render 'welcome')
  end

  # def after_login
  #   if current_user.present?
  #     render partial: 'layouts/waiting_for_assignment' if current_user.auction_id.blank?
  #     @players = current_user&.team&.players
  #     @matches = Match.where(auction_id: current_user.auction_id).order(created_at: :asc).uniq
  #     @leader_in_scorecard = find_leader_for_match
  #     data = {}
  #     @matches.each do |match|
  #       data[match.match_name] = [find_poistion_in_match(match.match_name), find_points_in_match(match.match_name)]
  #     end
  #     @user_data = data
  #   else
  #     redirect_to root_path, notice: 'UnAuthorized Access, Please try to login again'
  #   end
  # end

  def after_login # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    if current_user.present?
      render partial: 'layouts/waiting_for_assignment' if current_user.auction_id.blank?
      @players = current_user&.team&.players
      @matches = Match.where(auction_id: current_user.auction_id).order(created_at: :asc).uniq
      @pagy, @match_points = pagy(current_user.team.match_points.order(created_at: :desc))
      # @match_points = current_user.team.match_points.order(created_at: :desc)
      # @scorecard_leader = current_user.find_scorecard_leader
      # @leader_in_scorecard = find_leader_for_match
      data = {}

      @user_data = Match.order(created_at: :asc).uniq
                        .map do |match|
        data[match.match_name] =
          MatchPoint.find_poistion_in_match(match.match_name, current_user),
          MatchPoint.find_points_in_match(match.match_name, current_user)
      end
      # @matches.each do |match|
      #   data[match.match_name] = [find_poistion_in_match(match.match_name), find_points_in_match(match.match_name)]
      # end
      @user_data = data
    else
      redirect_to root_path, notice: 'UnAuthorized Access, Please try to login again'
    end
  end

  def live_auction
    @player = Player.find(params[:player_id])
  end

  def verify_otp; end

  def process_otp # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    user = User.friendly.find(params[:user_slug])
    params[:otp] =
      params[:digit1] + params[:digit2] + params[:digit3] + params[:digit4] + params[:digit5] + params[:digit6]
    if params[:otp] == user.otp
      user.update(otp_verified: true)
      sign_in(user)
      redirect_to after_login_path
      flash[:notice] = 'You have logged in successfully, Welcome to Patel-Predicts'
    else
      redirect_to verify_otp_path
      flash[:alert] = 'Invalid OTP!!'
    end
  end

  def resend_otp
    new_otp = rand(100_000..999_999)
    user = User.friendly.find(params[:user_slug])
    user.update(otp: new_otp)
    WelcomeMailer.with(otp: new_otp, username: user.username,
                       email: user.email).resend_otp.deliver_now
    redirect_to verify_otp_path, notice: 'Otp has been resent to your Email successfully'
  end

  def players_by_team # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    team_id = params[:team_id]
    match_name = params[:match_name]
    if team_id
      team = Team.find(team_id)
      current_match_teams = match_name.split(' vs ') if match_name.present?
      puts '++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++'
      puts '++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++'
      puts '++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++'
      puts { "value of week_start_date:- #{find_current_week_start_date}" }
      puts '++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++'
      puts '++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++'
      puts '++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++'
      puts '++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++'
      player_ids = team.user.weekly_user_teams.where(week_start_date: find_current_week_start_date).pluck(:playing11)
      player_ids = team.user.weekly_user_teams.last.playing11 if player_ids.blank?
      teams = current_match_teams.map { |name| name.split(' (')[0].upcase }
      players = team.players.where(id: player_ids, team_name: teams)
                    .map { |player| [player.name, player.id] }
      render json: { options: players }
    else
      render json: { options: [] }
    end
  end

  def compute_match_team_points
    @user = User.find_by(username: params[:user][0])
    return if @user.blank?

    matches = @user.team.matches.where(match_name: params[:match_name])
    @players = matches.map(&:player)
    result = {}
    return if @players.compact.blank?

    @players.each do |player|
      result[player.name] = player.matches.where(match_name: params[:match_name]).first.points
    end
    @players_hash = result
    @players_hash
  end

  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Layout/LineLength
  def one_match_scorecard(match_name = nil)
    @match = params[:match_id] if params[:match_id].present?
    results = if match_name.present?
                MatchPoint.where(match_name:)&.pluck(:team_id, :total_points)
              else
                MatchPoint.where(match_name: @match).pluck(:team_id, :total_points)
              end
    team_hash = {}
    results.each do |team_id, total_points|
      team_name = Team.find(team_id).team_name
      team_hash[team_name] = total_points
    end
    @sorted_team_hash = team_hash.sort_by { |_team_name, total_points| - total_points }.to_h
    return unless @sorted_team_hash.length < User.where(auction_id: current_user&.auction_id).count

    redirect_to after_login_path,
                notice: 'Admin is currently updating scorecard of this match, will notify you once scorecard gets updated!'
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength, Layout/LineLength

  def points_table
    @filtered_users = User.where(auction_id: current_user.auction_id).order(final_total_points: :desc)
  end

  def edit_profile; end

  def update_profile
    if current_user.update_profile_count >= 3
      redirect_to after_login_path,
                  alert: 'Your Update Profile count had been exceeded, To continue updating, please pay another 600 to admin.'
      return
    end

    current_update_profile_count = current_user.update_profile_count
    return unless params[:username]

    current_user.update(username: params[:username],
                        update_profile_count: current_update_profile_count + 1)
    redirect_to after_login_path, notice: 'Username updated successfully'
  end

  private

  def team_params
    params.permit(:name)
  end

  # def find_poistion_in_match(match_name)
  #   team_ranking = MatchPoint.where(match_name:).order(total_points: :desc).pluck(:team_id)
  #   team_ranking.index(current_user.team.id)&.+ 1
  # end

  # def find_points_in_match(match_name)
  #   MatchPoint.where(match_name:, team: current_user&.team).first&.total_points
  # end

  # wc
  def find_current_week_start_date
    if %w[monday tuesday wednesday thursday].include?(Time.zone.now.strftime('%A').downcase)
      find_current_week_monday
    else
      find_current_week_friday
    end
  end

  def find_current_week_friday
    current_day_of_week = Time.zone.today.wday
    case current_day_of_week
    when 5 # Friday
      Date.current
    when 6 # saturday
      Date.current - 1.day
    when 0 # sunday
      Date.current - 2.days
    end
  end

  # IPL
  def find_current_week_monday
    days_to_monday = Date.current.wday - 1
    days_to_monday += 7 if days_to_monday.negative?
    Date.current - days_to_monday
  end

  # def find_leader_for_match
  #   all_users = User.where(auction_id: current_user.auction_id)
  #   highest_scorers = {}

  #   all_users.each do |user|
  #     matches = @matches.pluck(:match_name).uniq
  #     matches.each do |match|
  #       points = Match.where(team: user.team, match_name: match).pluck(:points).sum

  #       if highest_scorers[match].nil? || points > highest_scorers[match][:score]
  #         highest_scorers[match] = { player: user.username, score: points }
  #       end
  #     end
  #   end
  #   highest_scorers
  # end
end
