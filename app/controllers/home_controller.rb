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
# ==============================================================================
  # def after_login # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    # if current_user.present?
    #   render partial: 'layouts/waiting_for_assignment' if current_user.auctions.blank?
    #   @current_auction = params[:auction_id].present? ? Auction.find(params[:auction_id]) : current_user.auctions.last
    #   default_team = current_user.teams.where(auction: @current_auction).first
    #   @players = default_team.players
    #   @matches = Match.where(team: default_team).order(created_at: :asc).distinct
    #   @pagy, @match_points = pagy(
    #     default_team.match_points
    #                 .select('DISTINCT ON (match_name) match_points.*')
    #                 .order(match_name: :asc, created_at: :desc) # Include match_name in ORDER BY
    #   )
    #   return if @match_points.blank?
    #   data = {}

    #   @user_data = Match.order(created_at: :asc).uniq
    #                     .map do |match|
    #     data[match.match_name] =
    #       MatchPoint.find_poistion_in_match(match.match_name, default_team.id, @current_auction),
    #       MatchPoint.find_points_in_match(match.match_name, default_team.id, @current_auction)
    #   end
    #   @user_data = data
    # else
    #   redirect_to root_path, notice: 'UnAuthorized Access, Please try to login again'
    # end
  # end

  def after_login
    if current_user.present?
      render partial: 'layouts/waiting_for_assignment' if current_user.auctions.blank?

      @current_auction = params[:auction_id].present? ? Auction.find(params[:auction_id]) : current_user.auctions.last
      @default_team = current_user.teams.where(auction: @current_auction).first

      # Fetch players with preloaded associations
      # @players = @default_team.players.includes(:some_association)

      @today_matches = MatchSchedule.where(match_date: Date.current)

      # Fetch matches and match_points with caching
      @matches = Rails.cache.fetch("matches_#{@default_team.id}", expires_in: 1.hour) do
        Match.where(team: @default_team).order(created_at: :desc).distinct
      end

      @pagy, @match_points = pagy(
        Rails.cache.fetch("match_points_#{@default_team.id}", expires_in: 1.hour) do
          # Subquery to get the latest created_at record for each match_name
          # latest_match_points = default_team.match_points
          #                                  .select('DISTINCT ON (match_name) match_points.*')
          #                                  .order(match_name: :asc, created_at: :desc)

          latest_match_points = @default_team.match_points
                                 .joins("INNER JOIN matches ON matches.match_name = match_points.match_name")
                                 .select('DISTINCT ON (match_points.match_name) match_points.*, matches.match_date')
                                 .order('match_points.match_name ASC, match_points.created_at DESC, matches.match_date DESC')

          # Order the results by created_at in descending order
          @default_team.match_points
                      .where(id: latest_match_points.pluck(:id))
                      .order(created_at: :desc)
        end
      )

      return if @match_points.blank?

      # Fetch match data for the team with caching
      @user_data = Rails.cache.fetch("user_data_#{@default_team.id}_#{@current_auction.id}", expires_in: 1.hour) do
        match_data = fetch_match_data_for_team(@default_team.id, @current_auction)
        match_data.each_with_object({}) do |record, data|
          data[record.match_name] = [
            record.ranking,
            record.total_points
          ]
        end
      end
      filtered_teams = @current_auction.teams
                      .select("teams.*, (teams.grand_total - COALESCE(teams.penalty_points, 0)) AS adjusted_total")
                      .order("adjusted_total DESC")

      @current_rank = filtered_teams.index(@default_team) + 1
    else
      redirect_to root_path, notice: 'UnAuthorized Access, Please try to login again'
    end
  end

   def fetch_match_data_for_team(team_id, auction)
  # Subquery to calculate rankings for all teams
  subquery = MatchPoint
    .joins(:team)
    .where(teams: { auction_id: auction.id })
    .select(
      'match_points.match_name',
      'match_points.team_id',
      'match_points.total_points',
      'RANK() OVER (PARTITION BY match_points.match_name ORDER BY match_points.total_points DESC) AS ranking'
    ).to_sql

  # Use Arel.sql to wrap the subquery correctly
  ranked_match_points = "(#{subquery}) AS ranked_match_points"

  # Query from the subquery and filter by team_id
  MatchPoint
    .unscoped
    .from(ranked_match_points)
    .select('ranked_match_points.*')
    .where('ranked_match_points.team_id = ?', team_id)
    .order('ranked_match_points.match_name, ranked_match_points.ranking')
end

  # ===============================================================================

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
      player_ids = team.user.weekly_user_teams.where(week_start_date: find_current_week_start_date).pluck(:playing11)
      player_ids = team.user.weekly_user_teams.order(week_start_date: :asc).last.playing11 if player_ids.blank?
      teams = current_match_teams.map { |name| name.split(' (')[0].upcase }
      players = team.players.where(id: player_ids, team_name: teams)
                    .map { |player| [player.name, player.id] }
      render json: { options: players }
    else
      render json: { options: [] }
    end
  end

  def compute_match_team_points
    @data = {}
    @points_data = {}
    @auction = Auction.find(params[:auction_id])
    @user = @auction.users.where(slug: params[:user])&.first || @auction.users.where(username: params[:user])&.first
    # @user = Team.find_by(team_name: params[:user][0])&.user || Team.find_by(team_name: params[:user]).user # temp solution for client
    # @user = User.find_by(username: params[:user][0])
    return if @user.blank?

    @default_team = @user.teams.where(auction: @auction)&.first
    @selected_user_team = @user.teams.where(auction: @auction)&.first
    matches = @default_team.matches.where(match_name: params[:match_name])

    #CHAGE FFIRST TO LAST AFTER UPDATING THE POINTS
    # playing11_player_ids = if @user.weekly_user_teams.count > 1
    #                           @user.weekly_user_teams.where("week_end_date <= ?", Date.current)&.last
    #                        else
    #                         @user.teams.where(auction: default_auction)&.first.weekly_user_teams.last.playing11
    #                        end
    playing11_player_ids = @default_team.player_perfomace_points.where(match: matches.pluck(:match_name)).pluck(:player_id)
    @players = @selected_user_team.players.where(team_name: params[:match_name].split(' vs '), id: playing11_player_ids)
    result = {}
    @auction = default_auction
    return if @players.compact.blank?

    # @players.each do |player|
    #   result[player.name] = player.matches.where(match_name: params[:match_name]).first&.points
    # end
    # @players_hash = result

    @players.each do |player|
      pp_record = player.player_perfomace_points.where(match: params[:match_name], team: @selected_user_team)&.first
      if pp_record.present?
        @data[player.name] = player.player_perfomace_points.where(match: params[:match_name], team: @selected_user_team)&.first
        @points_data[player.name] = player.matches.where(match_name: params[:match_name])&.first&.points
      end
    end
    # @data = @data.compact_blank
    respond_to do |format|
      format.html # render the full HTML if needed
      format.js   # handle AJAX request
    end
  end

  # rubocop:disable Metrics/MethodLength, Layout/LineLength
  def one_match_scorecard(match_name = nil)
    @match = params[:match_id] if params[:match_id].present?
    @auction = params[:auction_id].present? ? Auction.find(params[:auction_id]) : current_user.auctions.last
    # results = if match_name.present?
    #             MatchPoint.joins(:team)
    #                       .where(match_name:, teams: { auction: current_auction })
    #                       .pluck(:team_id, :total_points)
    #             # MatchPoint.where(match_name:)&.pluck(:team_id, :total_points)
    #           else
    #              MatchPoint.joins(:team)
    #                        .where(match_name: @match, teams: { auction: current_auction })
    #                        .pluck(:team_id, :total_points)
    #             # MatchPoint.where(match_name: @match).pluck(:team_id, :total_points)
    #           end
    # team_hash = {}
    # results.each do |team_id, total_points|
    #   team_name = Team.find(team_id).team_name
    #   team_hash[team_name] = total_points
    # end
    # @current_auction_teams = default_auction.teams.sort_by { |team| -team.grand_total }
    @team1, @team2 = @match.split(" vs ")
    @team_points = {}
    default_auction.teams.each do|team|
      @team_points[team.team_name] = MatchPoint.where(match_name: @match, team:)&.first&.total_points
    end
    @team_points = @team_points.transform_values { |points| points || 0 }
                           .sort_by { |_, points| -points }
                           .to_h
    if @team_points.present?
    @current_auction_teams = default_auction.teams.sort_by { |team| -(@team_points[team.team_name] || 0) }
    @avg_score = @team_points.values.sum/(@current_auction_teams.count)
    @highest_score = @team_points.values.first
    @top_picks = Player.where(id: Match.find_top_picks(@match))
    @best_player = @top_picks.first
    @best_player_pp_record = PlayerPerfomacePoint.where(match: @match, is_mom: true)&.last
    @best_player_total_points = @best_player_pp_record&.player&.matches&.where(match_name: @match)&.last&.points
    @best_batsman = Match.find_best_batsman(@match)
    @best_batsman_pp_record = @best_batsman&.player_perfomace_points&.where(match: @match)&.last
    @best_batsman_total_points = @best_batsman&.matches&.where(match_name: @match)&.last&.points
    @best_bowler = Match.find_best_bowler(@match)
    @best_bowler_total_points = @best_bowler&.matches.where(match_name: @match)&.last&.points
    @best_bowler_pp_record = @best_bowler&.player_perfomace_points&.where(match: @match)&.last
    @current_user_batsmans = default_team.players
                                         .joins(:player_perfomace_points)
                                         .where("player_perfomace_points.match = ? AND player_perfomace_points.runs > ?", @match, 0)

    @current_user_bowlers = default_team.players
                                        .joins(:player_perfomace_points)
                                        .where("player_perfomace_points.match = ? AND player_perfomace_points.overs_bowled > ?", @match, 0)
    @current_user_fielders = default_team.players
                                         .joins(:player_perfomace_points)
                                         .where(
                                            player_perfomace_points: { match: @match }
                                          )
                                         .where(
                                            "player_perfomace_points.catches > ? OR player_perfomace_points.run_outs > ?", 
                                            0, 
                                            0
                                          )
  end

    # @sorted_team_hash = team_hash.sort_by { |_team_name, total_points| - total_points }.to_h
    # return unless @sorted_team_hash.length < User.where(auction_id: current_user&.auction_id).count

    # redirect_to after_login_path,
    #             notice: 'Admin is currently updating scorecard of this match, will notify you once scorecard gets updated!'
  end
  # rubocop:enable Metrics/MethodLength, Layout/LineLength

  # def points_table
  #   auction = params[:auction_id].present? ? Auction.find(params[:auction_id]) : current_user.auctions.last
  #   @filtered_teams = auction.teams.order(grand_total: :desc)
  #   @current_user_team = current_user.teams.where(auction:).first
  #   @default_auction = default_auction
  # end

  def points_table
  auction = params[:auction_id].present? ? Auction.find(params[:auction_id]) : current_user.auctions.last

  # Calculate adjusted total (grand_total - penalty_point) for each team and order by it in descending order
  @filtered_teams = auction.teams
                           .select('teams.*, (teams.grand_total - COALESCE(teams.penalty_points, 0)) as adjusted_total')
                           .order('adjusted_total DESC')

  @current_user_team = current_user.teams.where(auction: auction).first
  @default_auction = default_auction
end

  def edit_profile; end

  def update_profile
    if current_user.update_profile_count >= 10
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

  def default_auction
    params[:auction_id].present? ? Auction.find(params[:auction_id]) : current_user.auctions.last
  end

  def default_team
    current_user.teams.where(auction: default_auction)&.first
  end

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



# Match.last.id => 42
# MatchPoint.last.id => 16
# PlayerPerfomacePoint.last.id => 42

# AFTER SECOND MATCH

# Match.last.id => 83
# MatchPoint.last.id => 32
# PlayerPerfomacePoint.last.id => 83


# reload!; match_id = '112409'; PointsCalculator.new(match_id).calculate_total_points