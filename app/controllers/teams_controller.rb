# frozen_string_literal: true

class TeamsController < ApplicationController # rubocop:disable Metrics/ClassLength
  before_action :authenticate_user!

  def new # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    if allowed_to_change_team?
      @team = Team.friendly.find(params[:team_id])
      @squad = current_user&.team&.players&.order(bench: :asc)
      @bench_players = current_user.team.players.where(bench: true)
      @playing_11_players = current_user.team.players.where(bench: false)
      @wicket_keeper = @playing_11_players.where(role: 'wicket_keeper')
      @batsman = @playing_11_players.where(role: 'batsman')
      @all_rounder = @playing_11_players.where(role: 'all_rounder')
      @bowler = @playing_11_players.where(role: 'bowler')
    else
      flash[:notice] = 'You can only change your playing 11 on Saturday and Sunday.'
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
    render partial: 'layouts/insufficient_analysis_data' if current_user.team.match_points.count <= 5
    @player_perfomance = current_user.team.players
                                     .order(points: :desc)
                                     .where(bench: false)
                                     .group_by(&:name).transform_values do |v|
      v.first.points
    end
    @player_team_breakdown = current_user.team.players.group(:team_name).count
    @user_rankings_data = current_user.rankings_data
    @display_users = (current_user.auction.users - [current_user])
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
    @other_players = User.where(auction_id: current_user.auction_id).order(created_at: :desc)
  end

  def other_players_team_detail # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    @user = User.friendly.find(params['user_slug'])
    if @user.weekly_user_teams.blank?
      redirect_to other_players_team_path, alert: 'User has not created his team yet!'
      return
    end
    playing11_ids = @user.weekly_user_teams.last.playing11
    @playing11_players = @user&.team&.players&.where(id: playing11_ids)

    bench_ids = @user.weekly_user_teams.last.bench
    @bench_players = @user&.team&.players&.where(id: bench_ids)
    week = params[:week] || 1
    change_week = params[:week].present?
    @playing_11_changed_player_ids, @bench_changed_player_ids = WeeklyUserTeam.current_week_changes(@user.id, week,
                                                                                                    change_week)

    update_players if params['week'].present?
  end

  def update_players # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    user_all_week_team_in_order = @user.weekly_user_teams.order(week_start_date: :asc)
    playing11_ids = user_all_week_team_in_order[params['week'].to_i - 1]&.playing11
    playing11_ids = @user.weekly_user_teams.order(created_at: :asc).last.playing11 if playing11_ids.blank?
    @playing11_players = @user&.team&.players&.where(id: playing11_ids)

    bench_ids = user_all_week_team_in_order[params['week'].to_i - 1]&.bench
    bench_ids = @user.weekly_user_teams.order(created_at: :asc).last.bench if bench_ids.blank?
    @bench_players = @user&.team&.players&.where(id: bench_ids)
  end

  def submit_team
    if check_team_format
      upsert_weekly_team
      redirect_to after_login_path, notice: 'Team Submitted Successfully'
    else
      redirect_to team_new_team_path(current_user.team), alert: playing_11_errors.to_s
    end
  end

  def power_perfomers
    render partial: 'layouts/insufficient_analysis_data' if current_user.team.match_points.count <= 5
    users = current_user.auction.users
    players = users.map { |user| user.team.players }.flatten
    @sorted_players = players.sort_by { |player| -player.points }.first(11)
    @owners = @sorted_players.map(&:owner)
  end

  def team_performance
    render partial: 'layouts/insufficient_analysis_data' if current_user.team.match_points.count <= 5
    @players = current_user.team.players
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
    matches = @player.matches

    owner = @player.team.user.username
    player = { name: @player.name, image: "#{@player.name}.jpeg" }
    matches = matches.map { |match| { name: match.match_name, points: match.points } }
    total_matches = matches.count

    if matches.blank? # display player summary who played 0 matches
      player_with_highest_matches = Player.joins(:matches)
                                          .group(:id)
                                          .order('COUNT(matches.id) DESC')
                                          .first.matches
      matches = player_with_highest_matches.map { |_match| { name: '-', points: 0 } }
      total_matches = 0
    end

    total_points = @player.points || 0
    average_points = total_matches.zero? ? 0 : (total_points.to_f / total_matches)
    highest_score =  matches.pluck(:points).max || 0

    data = {
      player:,
      matches:,
      owner:,
      total_matches:,
      total_points:,
      average_points:,
      highest_score:
    }
    # Render the partial as a string
    player_performance_card_html = render_to_string(partial: 'player_performance_card', locals: { data: })

    render json: { player_data: data, player_performance_card_html: }
  end

  def move_players
    move_action = params[:move_action] || ''
    player_ids = params[:player_ids] || []

    if player_ids.present? && move_action.present?
      players = Player.where(id: player_ids)
      players.each { |player| player.update!(bench: move_action == 'bench') }
      render json: { notice: 'Player moved successfully', success: true }
    else
      render json: { error: 'Something went wrong.', success: false }
    end
  end

  private

  def team_params
    params.fetch(:team, {}).permit(:team_name, :user_id)
  end

  def allowed_to_change_team?
    today = Time.zone.now.in_time_zone('Mumbai')
    today.saturday? || today.sunday? || current_user.id == 1
  end

  # rubocop:disable Rails/SkipsModelValidations, Metrics/AbcSize
  def upsert_weekly_team
    week_start_date = next_monday_date(Time.zone.today)
    user_weekly_team_record = current_user.weekly_user_teams.where(week_start_date:).first
    playing11_player_ids = current_user.team.players.where(bench: false).pluck(:id)
    bench_player_ids = current_user.team.players.where(bench: true).pluck(:id)
    if user_weekly_team_record.present?
      user_weekly_team_record.update_columns(playing11: playing11_player_ids, bench: bench_player_ids)
    else
      current_user.weekly_user_teams.create(week_start_date:, week_end_date: next_sunday_date(Time.zone.today),
                                            playing11: playing11_player_ids, bench: bench_player_ids)
    end
  end
  # rubocop:enable Rails/SkipsModelValidations, Metrics/AbcSize

  def next_monday_date(current_date)
    days_until_next_monday = (1 - current_date.wday) % 7
    current_date + days_until_next_monday
  end

  def next_sunday_date(date)
    day = date.strftime('%A')
    day == 'Saturday' ? date + 8.days : date + 7.days
  end

  def multi_users_analysis(selected_user) # rubocop:disable Metrics/MethodLength
    return if selected_user.blank?

    @all_users = if selected_user.include?('all_users')
                   User.where(auction_id: current_user.auction_id)
                 else
                   User.where(auction_id: current_user.auction_id, id: selected_user)
                 end

    all_user_data = []
    @all_users.each do |user|
      user_data = {
        name: user.username,
        data: user.rankings_data
      }
      all_user_data << user_data
    end
    all_user_data << { name: current_user.username, data: current_user.rankings_data }
    all_user_data
  end

  def playing_11_errors # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    errors = {}
    playing11_players = current_user.team.players.where(bench: false)
    player_counts = playing11_players.group(:role).count
    player_teams = playing11_players.pluck(:team_name)
    player_counts_by_team = player_teams.group_by do |element|
      player_teams.count(element)
    end.transform_values(&:uniq)

    if playing11_players.length != 11
      errors['message'] = 'Please select 11 players'
    elsif player_counts['batsman'].to_i < 2
      errors['message'] = 'You have to select minimum 2 batsman'
    elsif player_counts['wicket_keeper'].to_i < 1
      errors['message'] = 'You have to select atleast one Wicket-Kepper'
    elsif player_counts['bowler'].to_i < 3
      errors['message'] = 'You have to select atleast 3 bowlers'
    elsif playing11_players.where(foreigner: true).count > 4
      errors['message'] = 'You can only select 4 overseas-players'
    elsif player_counts_by_team.keys.any? { |k| k > 3 }
      team = player_counts_by_team.select { |key, _| key > 3 }.values.flatten.first
      errors['message'] = "You can only select max-3 players of team - #{team}"
    end
    errors['message']
  end

  # rubocop:disable Layout/LineLength, Metrics/AbcSize
  def check_team_format
    playing11_players = current_user.team.players.where(bench: false)
    overseas_players = current_user.team.players.where(bench: false, foreigner: true)
    batsman = playing11_players.where(role: 'batsman')
    wk = playing11_players.where(role: 'wicket_keeper')
    bowler = playing11_players.where(role: 'bowler')
    player_teams = playing11_players.pluck(:team_name)
    player_counts_by_team = player_teams.group_by do |element|
      player_teams.count(element)
    end.transform_values(&:uniq)

    playing11_players.length == 11 && overseas_players.length <= 4 && batsman.length >= 2 && wk.length >= 1 && bowler.length >= 3 && player_counts_by_team.keys.none? { |k| k > 3 }
  end
  # rubocop:enable Layout/LineLength, Metrics/AbcSize
end
