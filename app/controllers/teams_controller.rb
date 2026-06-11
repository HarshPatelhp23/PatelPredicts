# frozen_string_literal: true

class TeamsController < ApplicationController # rubocop:disable Metrics/ClassLength
  before_action :authenticate_user!

  def update_purse
    @team = Team.find(params[:id])
    sold_amount = params[:sold_amount].to_f
    
    @team.remaining_purse -= sold_amount
    
    if @team.save
      render json: { success: true, remaining_purse: @team.remaining_purse }
    else
      render json: { success: false }, status: :unprocessable_entity
    end
  end

  def new # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    flash.keep if flash.any?
    if allowed_to_change_team?
      @team = Team.friendly.find(params[:team_id])
      # @team = Team.friendly.find(params[:team_slug])
      @squad = @team.players&.order(bench: :asc)
      @bench_players = @team.players_teams.where(bench: true)
      @playing_11_players = @team.players_teams.where(bench: false)
      @playing_11_overseas_players = @team.players.where(foreigner: true)
                                          .joins(:players_teams)
                                          .where(players_teams: { team: @team, bench: false })

      @playing_11_indian_players = @team.players.where(foreigner: false)
                                                .joins(:players_teams)
                                                .where(players_teams: { team: @team, bench: false })
      @players = @team.players.where(id: @playing_11_players)
      # @wicket_keeper = @playing_11_players.where(role: 'wicket_keeper')
      @team_players = @team.players.where(id: @playing_11_players.pluck(:player_id))
      @team_bench_players = @team.players.where(id: @bench_players.pluck(:player_id))
      @wicket_keeper = @team_players.where(role: 'wicket_keeper')
      @playing11_wicket_keepers = @team_players.where(role: 'wicket_keeper')
      # @batsman = @playing_11_players.where(role: 'batsman')
      @batsman = @team_players.where(role: 'batsman')
      @playing11_batsmans = @team_players.where(role: 'batsman')
      # @all_rounder = @playing_11_players.where(role: 'all_rounder')
      @all_rounder = @team_players.where(role: 'all_rounder')
      @playing11_all_rounders = @team_players.where(role: 'all_rounder')
      # @bowler = @playing_11_players.where(role: 'bowler')  
      @bowler = @team_players.where(role: 'bowler')
      @playing11_bowlers = @team_players.where(role: 'bowler')
      @week_start_date = find_week_dates[:week_start_date]
      @week_end_date = find_week_dates[:week_end_date]
      @current_week_matches = MatchSchedule.where(match_date: @week_start_date..@week_end_date)
      @next_week_start_date = find_week_dates[:next_week_start_date]
      @next_week_end_date = find_week_dates[:next_week_sunday]
      @next_week_matches = MatchSchedule.where(match_date: @next_week_start_date..@next_week_end_date)
    else
      flash[:error] = 'OOPS!, Team submission for this week had been closed!'
      redirect_to after_login_path
    end
  end

  def create
    @team = Team.create(team_name: params[:team_name], user_id: current_user.id)
    if @team.save
      redirect_to after_login_path, notice: 'Team-Name given successfully'
    else
      flash.now[:errors] = @team.errors.full_messages.to_sentence
      render 'home/after_login', status: :unprocessable_entity
    end
  end

  def analysis # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    # render partial: 'layouts/insufficient_analysis_data'
    @default_team = default_team
    @player_perfomance = default_team.players
                                     .order(points: :desc)
                                     .group_by(&:name).transform_values do |v|
      v.first.players_teams.where(team: default_team)&.first&.points
    end
    @player_team_breakdown = default_team.players.group(:team_name).count
    @user_rankings_data = current_user.rankings_data(default_auction.id, default_team.id)
    @display_users = (default_auction.users - [current_user])
    @selected_user = params['selected_users'] || []
    @all_users = multi_users_analysis(@selected_user) if @selected_user
  end

  def update_playing_11
    player = Player.find(params[:player_id]) if params[:player_id]
    if player.bench?
      player.update(bench: false)
    else
      player.update(bench: true)
    end
    redirect_to team_new_team_path(current_user.team.id), notice: 'Player updated successfully'
    @bench_players = current_user.team.players.where(bench: true)
    @playing_11_players = current_user.team.players.where(bench: false)
  end

  def other_player_teams
    # flash.keep if flash.any?
    @auction = params[:auction_id].present? ? Auction.find(params[:auction_id]) : current_user.auctions.last

    @other_players = @auction.users.includes(:teams).sort_by do |player|
      team = player.teams.find { |t| t.auction == @auction }
      if team
        (team.grand_total || 0) - (team.penalty_points || 0)  # Calculate net points
      else
        0
      end
    end.reverse
  end

  # def other_player_teams
  #   @auction = params[:auction_id].present? ? Auction.find(params[:auction_id]) : current_user.auctions.last
  #   # @other_players = @auction.users.order(created_at: :desc)
  #   @other_players = @auction.users.sort_by do |player|
  #     team = player.teams.where(auction: @auction)
  #     player.weekly_user_teams.blank? ? 1 : 0  # Players with submissions come first
  #   end
  # end

  def other_players_team_detail
    @user = User.friendly.find(params['user_slug'])
    if @user.weekly_user_teams.blank?
      redirect_to other_players_team_path, alert: "User has not submitted his team yet!"
      return
    end
    @user_team = @user.teams.count > 1 ? @user.teams.where(auction: default_auction)&.last : @user.teams.last
    week = params[:week].to_i || 1
    # playing11_ids = @user.weekly_user_teams.where(team: @user_team).order(week_start_date: :asc).last.playing11
    # @playing11_players = @user.teams&.where(auction: default_auction)&.first&.players&.where(id: playing11_ids)
    # playing11_ids = if (@user.weekly_user_teams.where(team: @user_team).count > 1) && (params[:week].to_i > 1)
    #                   @user.weekly_user_teams
    #                        .where(team: @user_team)
    #                        .where("week_end_date >= ?", Date.current)&.last&.playing11 || @user_team.weekly_user_teams.last.playing11
    #                 else
    #                   @user.weekly_user_teams.where(team: @user_team)&.first&.playing11
    #                 end

    playing11_ids = @user.weekly_user_teams.where(team: @user_team, week:)&.last&.playing11
    @playing11_players = @user_team.players.where(id: playing11_ids)
    

    # bench_ids = @user.weekly_user_teams.where(team: @user_team).order(week_start_date: :asc).last.bench
    # @bench_players = @user&.teams&.where(auction: default_auction)&.first&.players&.where(id: bench_ids)

    # bench_ids = if (@user.weekly_user_teams.where(team: @user_team).count > 1) && (params[:week].to_i > 1)
    #               @user.weekly_user_teams
    #                    .where(team: @user_team)
    #                    .where("week_end_date >= ?", Date.current)&.last&.bench || @user_team.weekly_user_teams.last.bench
    #             else
    #               @user.weekly_user_teams.where(team: @user_team)&.first&.bench
    #             end
    bench_ids = @user.weekly_user_teams.where(team: @user_team, week:)&.last&.bench
    @bench_players = @user_team.players.where(id: bench_ids)
   

    # change_week = params[:week].present?
    # @playing_11_changed_player_ids, @bench_changed_player_ids = WeeklyUserTeam.current_week_changes(@user, @user_team, week, default_auction)
    if @user.weekly_user_teams.where(team: @user_team).count > 1 && params[:week].to_i != 1
      @playing_11_changed_player_ids = @user.weekly_user_teams.where(team: @user_team, week: params[:week])&.last&.team_changes&.fetch('bench_changes') ||  @user.weekly_user_teams.where(team: @user_team)&.last&.team_changes['bench_changes']
      @bench_changed_player_ids = @user.weekly_user_teams.where(team: @user_team, week: params[:week])&.last&.team_changes&.fetch("playing11_changes") || @user.weekly_user_teams.where(team: @user_team)&.last&.team_changes["playing11_changes"]
    elsif params[:week].to_i == 1
      @playing_11_changed_player_ids = @user.weekly_user_teams.where(team: @user_team, week:)&.first.playing11
      @bench_changed_player_ids = @user.weekly_user_teams.where(team: @user_team, week:)&.first.bench
    else
      @playing_11_changed_player_ids, @bench_changed_player_ids = [[], []]
    end
    # @playing_11_changed_player_ids, @bench_changed_player_ids = WeeklyUserTeam.current_week_changes(@user.id, default_team, week,
    #                                                                                                 change_week)
    update_players(params['week']) if params['week'].present?
  end

  def update_players(week) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    # user_team_ids = @user.teams.pluck(:id)
    @user_team = @user.teams.where(slug: params[:user_slug])&.first
    # playing11_ids = if (@user.weekly_user_teams.where(team: @user_team).count) > 1 && (params[:week].to_i > 1)
    #                   @user.weekly_user_teams
    #                        .where(team: @user_team)
    #                        .where("week_end_date >= ?", Date.current)&.last&.playing11 || @user_team.weekly_user_teams.last.playing11
    #                 else
    #                   @user.weekly_user_teams.where(team: @user_team)&.first&.playing11
    #                 end


    playing11_ids = @user.weekly_user_teams.where(team: @user_team, week:)&.last&.playing11 || @user.weekly_user_teams.where(team: @user_team)&.last&.playing11 
    
    @playing11_players = @user_team&.players.where(id: playing11_ids)

    # bench_ids = if (@user.weekly_user_teams.where(team: @user_team).count > 1) && (params[:week].to_i > 1)
    #               @user.weekly_user_teams
    #                    .where(team: @user_team)
    #                    .where("week_end_date >= ?", Date.current)&.last&.bench || @user_team.weekly_user_teams.last.bench
    #             else
    #               @user.weekly_user_teams.where(team: @user_team)&.first&.bench
    #             end

    bench_ids = @user.weekly_user_teams.where(team: @user_team, week:)&.last&.bench || @user.weekly_user_teams.where(team: @user_team)&.last&.bench
    @bench_players = @user_team.players.where(id: bench_ids)
  end

  # def submit_team
  #   respond_to do |format|
  #     if check_team_format
  #       upsert_weekly_team
  #       flash.now[:notice] = "Team Submitted Successfully."
  #       format.html { redirect_to after_login_path }
  #       format.turbo_stream
  #     else
  #       flash.now[:alert] = playing_11_errors.to_s
  #       format.html { redirect_to after_login_path }
  #       format.turbo_stream
  #     end
  #   end
  # end

  # def submit_team
  #   respond_to do |format|
  #     if check_team_format
  #     # if true
  #       upsert_weekly_team
  #       format.html { redirect_to after_login_path, notice: "eam Submitted Successfully." }
  #       format.turbo_stream { redirect_to after_login_path, notice: "Team Submitted Successfully." }
  #     else
  #       format.html { redirect_to team_new_team_path(default_team), alert: "#{playing_11_errors.to_s}" }
  #       format.turbo_stream { redirect_to team_new_team_path(default_team), alert: "#{playing_11_errors.to_s}" }
  #     end
  #   end
  # end

  def submit_team
    flash.keep if flash.any?
    if check_team_format
    # if true
      upsert_weekly_team
      redirect_to after_login_path, notice: 'Team Submitted Successfully.'
    else
      # flash[:alert] = playing_11_errors.to_s
      redirect_to team_new_team_path(default_team, auction: default_auction), alert: playing_11_errors
      # render :new
    end
  end

  def power_perfomers
    @auction = params[:auction_id].present? ? Auction.find(params[:auction_id]) : current_user.auctions.last
    @c_team = current_user.teams.where(auction: @auction).first
    # render partial: 'layouts/insufficient_analysis_data' if @c_team.match_points.count <= 2
    @orange_cap_players = PlayerPerfomacePoint.orange_cap_players(@auction.id)
    @purple_cap_players = PlayerPerfomacePoint.purple_cap_players(@auction.id)
    top_fantasy_player_ids = PlayerPerfomacePoint.top_fantasy_players(@auction.id)
    players_by_id = Player.where(id: top_fantasy_player_ids).index_by(&:id)
    @top_fantasy_players = top_fantasy_player_ids.map { |id| players_by_id[id] }.compact
  end
  # def power_perfomers
  #   auction = params[:auction_id].present? ? Auction.find(params[:auction_id]) : current_user.auctions.last
  #   c_team = current_user.teams.where(auction:).first
  #   render partial: 'layouts/insufficient_analysis_data' if c_team.match_points.count <= 2
  #   users = auction.users
  #   players = c_team.players
  #   current_user_pool_teams = auction.teams.pluck(:id)
  #   @top_11_player_ids =PlayersTeam.where(team: current_user_pool_teams).order(points: :desc).pluck(:player_id).first(11)
  #    @top_11_players = Player.where(id: @top_11_player_ids).map do |player|
  #     player_team = player.players_teams.joins(:team).where(teams: { auction: default_auction }).first
  #     {
  #       id: player.id,
  #       name: player.name,
  #       sold_price: player.sold_price,
  #       role: player.role,
  #       team_name: player.team_name,
  #       owner: player_team.team.team_name,
  #       points: player_team.points || 0
  #     }
  #   end.sort_by { |player| -player[:points] }
  #   @owners = @top_11_players.map { |player| player[:owner] }
  # end

  def team_performance
    @auction = default_auction
    c_team = current_user.teams.where(auction: @auction).first
    # render partial: 'layouts/insufficient_analysis_data' if c_team.match_points.count <= 2
    @players = c_team.players
  end

  def search_players
    search_query = params[:name]
    players = Player.where('name ILIKE ?', "%#{search_query}%")
    suggestions = players.map { |player| { id: player.id, name: player.name } }
    render json: suggestions
  end

  def player_data # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    return if params[:player_id].blank?

    @player = Player.find(params[:player_id])
    team = @player.teams.where(auction: default_auction)&.first
    matches = @player.matches.where(auction_id: default_auction.id, team:)

    owner = @player.teams.where(auction: default_auction)&.first&.user.username
    image_path = Rails.root.join('app', 'assets', 'images', "#{@player.name}.jpeg")
    image = File.exist?(image_path) ? "#{@player.name}.jpeg" : 'default_player_image.jpeg'
    player = { name: @player.name, image: }
    matches = matches.map { |match| { name: match.match_name, points: match.points } }
    total_matches = matches.count
    if matches.blank? # display player summary who played 0 matches
      player_with_highest_matches = Player.joins(:matches)
                                          .group(:id)
                                          .order('COUNT(matches.id) DESC')
                                          .first&.matches
      matches = player_with_highest_matches&.map { |_match| { name: '-', points: 0 } }
      total_matches = 0
    end
    total_points = @player.players_teams.joins(:team).where(team: default_auction.teams).pluck(:points).first || 0
    average_points = total_matches.zero? ? 0 : (total_points.to_f / total_matches)
    highest_score =  matches&.pluck(:points)&.max || 0
    current_pool_teams = default_auction.teams.pluck(:id)
    price_int = @player.players_teams.where(team_id: current_pool_teams).first.sold_price
    # price_int = @player.players_teams.where(team: default_team).first.sold_price
    price = price_int < 1 ? "#{price_int} L" : "#{price_int} CR"

    data = {
      player:,
      matches:,
      owner:,
      total_matches:,
      total_points:,
      average_points:,
      highest_score:,
      price:
    }
    # Render the partial as a string
    player_performance_card_html = render_to_string(partial: 'player_performance_card', locals: { data: })

    render json: { player_data: data, player_performance_card_html: }
  end

  # def show
  #   @player = Player.find(params[:player_id])
  #   @auction = default_auction
  #   @team = @player.teams.where(auction: @auction).first
  #   @matches = @player.matches.where(auction: @auction, team: @team).order(match_date: :desc)
    
  #   # Calculate stats
  #   @total_points = @player.players_teams.joins(:team).where(team: @auction.teams).pluck(:points).first || 0
  #   @average_points = @matches.size.zero? ? 0 : (@total_points.to_f / @matches.size).round(2)
  #   @highest_score = @matches.maximum(:points) || 0
  #   @price = @player.players_teams.where(team: @auction.teams).first.sold_price
    
  #   # For charts
  #   @points_data = @matches.pluck(:match_name, :points)
  #   @performance_trend = @matches.order(match_date: :asc).pluck(:match_date, :points)

  #   @best_match = @matches.order(points: :desc).first
  #   @best_match_opponent = @best_match&.match_name&.split(' vs ').last || 'N/A'
  #   @lowest_score = @matches.minimum(:points) || 0
  #   @worst_match = @matches.order(points: :asc).first
  #   @worst_match_opponent = @worst_match&.match_name&.split(' vs ').last|| 'N/A'
  #   @good_performances_count = @matches.where('points >= 25').count
  #   @recent_form = @matches.last(5).map { |m| m.points }
    
  #   # For consistency rating (example calculation)
  #   @consistency_rating = calculate_consistency_rating
  #   @impact_index = calculate_impact_index
  #   @value_for_money = @price.to_f / @average_points rescue 0
    
  #   respond_to do |format|
  #     format.html
  #     format.json { render json: { player: @player, stats: { runs: 400, wickets: 2 } } }
  #   end
  # end

  def move_players
    move_action = params[:move_action] || ''
    player_ids = params[:player_ids] || []

    if player_ids.present? && move_action.present?
      players = Player.where(id: player_ids)
      players.each { |player| player.players_teams.where(team: default_team)&.first.update!(bench: move_action == 'bench') }
      render json: { notice: 'Player moved successfully', success: true }
    else
      render json: { error: 'Something went wrong.', success: false }
    end
  end

  private

  def calculate_consistency_rating
    return 0 if @matches.size.zero?

    average = @average_points
    deviations = @matches.pluck(:points).map { |p| (p - average).abs }
    (100 - (deviations.sum.to_f / @matches.size)).round(2)
  end

  def calculate_impact_index
    return 0 if @matches.size.zero?
    (@matches.sum(:points).to_f / (@matches.size * 10) * 100).round(2)
  end

  def find_week_dates
    today = Date.today
    
    # Find the current/next Monday (week start date)
    week_start_date = today + ((1 - today.wday) % 7)
    week_start_date = week_start_date == today ? today : week_start_date
    
    # Find the current week's Sunday (week end date)
    week_end_date = week_start_date + 6
    
    # Find next week's Monday and Sunday
    next_week_start_date = week_start_date + 7
    next_week_sunday = week_end_date + 7
    
    {
      week_start_date: week_start_date,
      week_end_date: week_end_date,
      next_week_start_date: next_week_start_date,
      next_week_sunday: next_week_sunday
    }
  end

  def team_params
    params.fetch(:team, {}).permit(:team_name, :user_id)
  end

  def allowed_to_change_team?
    today = Time.zone.now.in_time_zone('Mumbai')
    today.saturday? || today.sunday?  || current_user.id == 1
  end

  # rubocop:disable Rails/SkipsModelValidations
  def upsert_weekly_team
    #UCOMMENT ME AFTER 1ST WEEK ONCE STATIC DATE IS USED
    today = Time.zone.now.in_time_zone('Mumbai')
    if today.saturday?
      week_start_date = Date.current + 2.day
    elsif today.sunday?
      week_start_date = Date.current + 1.day
    end
    # week_start_date = Date.new(2025, 2, 2)
    user_weekly_team_record = current_user.weekly_user_teams.where(week_start_date:, team: default_team).first
    playing11_player_ids = default_team.players_teams.where(bench: false).pluck(:player_id)
    bench_player_ids = default_team.players_teams.where(bench: true).pluck(:player_id)

    if user_weekly_team_record.present?
      user_weekly_team_record.update(playing11: playing11_player_ids, bench: bench_player_ids)
    else
      # week_end_date = Date.new(2026, 2, 8)
      week_end_date = next_sunday_date(Time.zone.today) #USE ME AFTER 1ST WEEK
      current_user.weekly_user_teams.create(week_start_date:, week_end_date:, team: default_team, playing11: playing11_player_ids, bench: bench_player_ids)

      #HARDCORE WEEK_START AND WEEK_END DATE
      # current_user.weekly_user_teams.create(week_start_date: Date.new(2025,3,17), week_end_date: Date.new(2025,3,23), team: default_team, playing11: playing11_player_ids, bench: bench_player_ids)


      # WC
      # current_user.weekly_user_teams.create(week_start_date:, week_end_date:,
      #                                       playing11: playing11_player_ids, bench: bench_player_ids)
    end
  end
  # rubocop:enable Rails/SkipsModelValidations

  def week_end_date
    case Date.current.wday
    when 0
      Date.current + 4.days
    when 4
      Date.current + 3.days
    when 6
      Date.current + 5.days
    end
  end

  def next_sunday_date(date)
    day = date.strftime('%A')
    day == 'Saturday' ? date + 8.days : date + 7.days
  end

  def multi_users_analysis(selected_user) # rubocop:disable Metrics/MethodLength
    return if selected_user.blank?

    @all_users = if selected_user.include?('all_users')
                   # User.where(auction: default_auction)
                   default_auction.users
                 else
                   # User.where(auction: default_auction, id: selected_user)
                   default_auction.users.where(id: selected_user)
                 end
    all_user_data = []
    @all_users.each do |user|
      user_team = user.teams.where(auction_id: default_auction.id)&.first
      user_data = {
        name: user.username,
        data: user.rankings_data(default_auction.id, user_team.id)
      }
      all_user_data << user_data
    end
    all_user_data << { name: current_user.username, data: current_user.rankings_data(default_auction.id, default_team.id) }
    all_user_data
  end

  def playing_11_errors # rubocop:disable Metrics/MethodLength
    errors = {}
    playing11_players_id = default_team.players_teams.pluck(:player_id)
    players = default_team.players.where(id: playing11_players_id).pluck(:id)
    playing11_players_teams_record = PlayersTeam.where(player_id: players, bench: false).pluck(:player_id)
    playing11_players = default_team.players.where(id: playing11_players_teams_record)
    player_counts = playing11_players.group(:role).count
    # player_teams = playing11_players.pluck(:team_name)
    # player_counts_by_team = player_teams.group_by do |element|
    #   player_teams.count(element)
    # end.transform_values(&:uniq)
    if playing11_players.length != 11
      errors['message'] = 'Please select 11 players'
    elsif player_counts['batsman'].to_i < 3
      errors['message'] = 'You have to select minimum 3 batsman'
    elsif player_counts['wicket_keeper'].to_i < 1
      errors['message'] = 'You have to select atleast one Wicket-Kepper'
    elsif player_counts['bowler'].to_i < 3
      errors['message'] = 'You have to select atleast 3 bowlers'
    elsif playing11_players.where(foreigner: true).count > 4
      errors['message'] = 'You can only select 4 overseas-players'
      # elsif player_counts_by_team.keys.any? { |k| k > 3 }
      #   team = player_counts_by_team.select { |key, _| key > 3 }.values.flatten.first
      #   errors['message'] = "You can only select max-3 players of team - #{team}"
    end
    errors['message']
  end

  def check_team_format
    playing11_players_ids = default_team.players_teams.where(bench: false).pluck(:player_id)
    # current_user.team.players.where(bench: false, foreigner: true)
    playing11_players = default_team.players.where(id: playing11_players_ids)
    batsman = playing11_players.where(role: 'batsman')
    all_rounder = playing11_players.where(role: 'all_rounder')
    wk = playing11_players.where(role: 'wicket_keeper')
    bowler = playing11_players.where(role: 'bowler')
    overseas_players = playing11_players.where(foreigner: true)
    # player_teams = playing11_players.pluck(:team_name)
    # player_counts_by_team = player_teams.group_by do |element|
    #   player_teams.count(element)
    # end.transform_values(&:uniq)

    playing11_players.length == 11 && batsman.length >= 3 && wk.length >= 1 && all_rounder.length >= 1 && bowler.length >= 3 && overseas_players.length <= 4
  end

  def default_auction
    params[:auction_id].present? ? Auction.find(params[:auction_id]) : current_user.auctions.last
  end

  def default_team
    default_team = current_user.teams.where(auction: default_auction).first
    default_team
  end
end
