# frozen_string_literal: true

class ScoreFetcher
  require 'responses/scorecard_response'
  attr_accessor :res, :series, :match_id

  SERIES = 'Indian Premier League 2025' # CHANGE IT TO => 'Indian Premier League 2025'
  # ct_2025 series_id = '9325'
  # indian-premier-league-2025 = '9237'
  include HTTParty
  base_uri 'https://cricbuzz-cricket.p.rapidapi.com'

  HEADERS = {
    'x-rapidapi-key' => Rails.application.credentials.dig(:rapid_api, :key),
    'x-rapidapi-host' => 'cricbuzz-cricket.p.rapidapi.com'
  }.freeze

  def initialize(end_point: '/matches/v1/recent')
    # @res = fetch_recent_matches(end_point) # Change to get dynamic
    # @res = Responses::ChampionsTrophy.champions_trophy_2025
    # @series = fetch_series
    # store_response(res: @res, series: @series)
    @match_id = find_todays_match_from_stored_data
  end

  def process_scorecard
    # users = User.all
    # users_pool = Auction.includes(:users).map { |auction| [auction.id, auction.users] }.to_h
    # match_id = find_match_for_today
    # match_id = '114960'
    return if match_id.blank?

    PointsCalculator.new(match_id).calculate_total_points
  end

   def find_todays_match_from_stored_data
    match_ids = []
    series_data = SeriesMatchResponse.where.not(series_res: '{}')&.last
    return nil unless series_data

    todays_date = Date.today.strftime("%a, %d %b %Y")
    match_details = series_data.series_res["matchDetails"].find do |detail|
      detail["matchDetailsMap"] && detail["matchDetailsMap"]["key"] == todays_date
    end
    return nil unless match_details

    # match_info = match_details["matchDetailsMap"]["match"].first["matchInfo"]
    match_info = match_details["matchDetailsMap"]["match"]
    match_info.each do |m_info|
      match_ids << m_info["matchInfo"]["matchId"].to_s
    end
    match_ids
  end

  def self.create_ipl_matches_series_reponse
    end_point = '/series/v1/9237'
    response = get(end_point, headers: HEADERS)
    if response.success?
      series_res = JSON.parse(response.body)
      SeriesMatchResponse.create(series_res:)
    end
  end

  def self.get_squad_ids
    end_point = '/series/v1/9237/squads' # 9237 is series_id
    response = get(end_point, headers: HEADERS)
    if response.success?
      squads_data = JSON.parse(response.body)['squads']
      squad_ids = squads_data.map { |squad| squad['squadId'] }

      SeriesMatchResponse.create!(
        match_data: nil,
        series_res: response.body,
        recent_match_res: nil
      )
      squad_ids
    else
      Rails.logger.error "Failed to fetch squad data: #{response.code} - #{response.message}"
      nil
    end
  rescue JSON::ParserError => e
    Rails.logger.error "Failed to parse API response: #{e.message}"
    nil
  end

  def self.update_cricbuzz_player_id
    series_match_response = SeriesMatchResponse.first

    if series_match_response&.series_res.present?
      squads_data = JSON.parse(series_match_response.series_res)['squads']

      squads_data.each do |squad|
        next unless squad['squadId'].present?

        squad_id = squad['squadId']
        team_name = squad['squadType']
        end_point = "/series/v1/9237/squads/#{squad_id}"

        response = ScoreFetcher.get(end_point, headers: HEADERS)

        if response.success?
          players_data = parse_response(response)
          update_player_id(players_data, team_name)
        end
      end
    end
  end

  def self.create_cricbuzz_players
    series_match_response = SeriesMatchResponse.first

    if series_match_response&.series_res.present?
      squads_data = JSON.parse(series_match_response.series_res)['squads']

      squads_data.each do |squad|
        next unless squad['squadId'].present?

        squad_id = squad['squadId']
        team_name = squad['squadType']
        end_point = "/series/v1/9237/squads/#{squad_id}"

        response = ScoreFetcher.get(end_point, headers: HEADERS)

        if response.success?
          players_data = parse_response(response)
          process_players_data(players_data, team_name)
          puts "++++++ DONE, TOTAL #{Player.count} players created successfully"
        else
          Rails.logger.error "Failed to fetch players for squad #{squad_id}: #{response.code} - #{response.message}"
        end
      end
    else
      Rails.logger.error "No series response data found in SeriesMatchResponse table."
      nil
    end
  end

  private

  def self.find_team_short_name(team_name)
    teams = {
      'Chennai Super Kings' => 'CSK',
      'Rajasthan Royals' => 'RR',
      'Kolkata Knight Riders' => 'KKR',
      'Sunrisers Hyderabad' => 'SRH',
      'Royal Challengers Bengaluru' => 'RCB',
      'Delhi Capitals' => 'DC',
      'Punjab Kings' => 'PBKS',
      'Mumbai Indians' => 'MI',
      'Gujarat Titans' => 'GT',
      'Lucknow Super Giants' => 'LSG'
    }
    teams[team_name]
  end

  def self.parse_response(response)
    JSON.parse(response.body)
  rescue JSON::ParserError => e
    Rails.logger.error "Failed to parse API response: #{e.message}"
    nil
  end

  def self.update_player_id(players_data, team_name)
    not_updated_players = []
    success_count = 0
    team_short_name = self.find_team_short_name(team_name)
    players_data['player'].each do |player_data|
      next if player_data["isHeader"].present?

      player = Player.where("LOWER(name) = LOWER(?)", player_data["name"])&.first
      if player.blank?
        not_updated_players << { cricbuzz_id: player_data["id"], player_name: player_data["name"] }
      end
      player&.update_columns(cricbuzz_player_id: player_data["id"])
      success_count += 1
    end
    puts "++++++++++++++++++++++++++++++++"
    puts "++++++++++++++++++++++++++++++++"
    puts "++++++++++++++++++++++++++++++++"
    puts "TOTAL PLAYERS:- #{Player.count}"
    puts "++++++++++++++++++++++++++++++++"
    puts "++++++++++++++++++++++++++++++++"
    puts "UPDATED PLAYERS:- #{success_count}"
    puts "++++++++++++++++++++++++++++++++"
    puts "++++++++++++++++++++++++++++++++"
    puts "++++++++++++++++++++++++++++++++"
    puts "NOT UPDATED PLAYERS:- #{not_updated_players}"
  end

  def self.process_players_data(players_data, team_name)
    team_short_name = self.find_team_short_name(team_name)
    players_data['player'].each do |player_data|
      next if player_data["isHeader"].present?

      player = Player.create(name: player_data["name"])
      role_mapping = {'Batter' => 'batsman', 'Batting Allrounder' => 'all_rounder', 'Bowling Allrounder' => 'all_rounder',  'WK-Batter' => 'wicket_keeper', 'Bowler' => 'bowler'  }
      player.role = Player.roles[role_mapping[player_data['role']]]
      player.team_name = team_short_name
      player.batting_style = player_data['battingStyle']
      player.bowling_style = player_data['bowlingStyle']
      player.save!
    end
  end

  def fetch_recent_matches(end_point)
    response = self.class.get(end_point, headers: HEADERS)
    parse_response(response)
  end

  def fetch_series
    raise 'Response not set. Call fetch_recent_matches first.' unless @res
    @series = res['typeMatches'].find do |type_match|
      type_match['seriesMatches'].any? do |series|
        series.dig('seriesAdWrapper', 'seriesName') == SERIES
      end
    end
  end

  def find_both_team_of_match
    res_team1, res_team2 = nil
    # series = Responses::ScorecardResponse.demo_series_res if series.blank?
    series['seriesMatches'].each do |s|
      s['seriesAdWrapper']['matches'].each do |match|
        match_info = match['matchInfo']
        res_team1 = match_info['team1']['teamSName']
        res_team2 = match_info['team2']['teamSName']
      end
    end
    [res_team1, res_team2]
  end

  def find_match_for_today
    matching_match_ids = []
    m1_teams, m2_teams = MatchSchedule.fetch_ipl_teams_for_today
    res_team1, res_team2 = find_both_team_of_match
    series['seriesMatches'].each do |ss|
      ss['seriesAdWrapper']['matches'].each do |match|
        match_info = match['matchInfo']
        res_team1 = match_info['team1']['teamSName']
        res_team2 = match_info['team2']['teamSName']

        if m1_teams.include?(res_team1) && m1_teams.include?(res_team2)
          matching_match_ids << match.fetch('matchInfo')['matchId']
          break
        end

        if m2_teams&.include?(res_team1) && m2_teams&.include?(res_team2)
          matching_match_ids << match.fetch('matchInfo')['matchId']
          break
        end
      end
      break if matching_match_ids.present?
    end
    matching_match_ids
  end

  def parse_response(response)
    response.success? ? response.parsed_response : handle_error(response)
  end

  def handle_error(response)
    Rails.logger.error("Error fetching data: #{response.code} - #{response.message}")
    raise StandardError, "Failed to fetch data: #{response.code} - #{response.message}"
  end

  def store_response(**attrs)
    allowed_columns = %i[match_data series_res recent_match_res]

    # Filter out only allowed columns from the provided attributes
    filtered_attrs = attrs.slice(*allowed_columns)
    return if filtered_attrs.empty?

    SeriesMatchResponse.create(filtered_attrs)
  end
end
