# frozen_string_literal: true
class PointsCalculator < ScoreFetcher
  require 'responses/scorecard_response'
  require 'levenshtein'
  require 'fuzzy_match'
  require 'amatch'

  attr_accessor :score, :auctions

  include HTTParty
  include ApplicationHelper
  base_uri 'https://cricbuzz-cricket.p.rapidapi.com'

  def initialize(match_id)
    @auctions = Auction.all
    @res = fetch_scorecard(match_id)
  end

  def fetch_scorecard(match_id)
    end_point = "/mcenter/v1/#{match_id}/hscard"
    response = self.class.get(end_point, headers: HEADERS)
    parse_response(response)
  end

  def find_match_teams
    # From the new response format, we need to extract team names differently
    # Look for team names in the scorecard
    team_names = []
    @res["scorecard"].each do |innings|
      team_names << innings["batteamsname"]
    end
    team_names.uniq
  end

  def calculate_total_points
    teams = find_match_teams
    team1, team2 = teams[0], teams[1]
    matches = []
    pp_record_ids = []
    create_wicket_desc(team1, team2)
    
    auctions.each do |auction|
      auction.teams.each do |user_team|
          
        # STEP-1:- First Update points of Playing-11 players
        if user_team.weekly_user_teams.count > 1
          playing11_ids = user_team.weekly_user_teams.where("week_start_date <= ?", Date.current)&.last&.playing11 || user_team.weekly_user_teams.last.playing11
        else
          playing11_ids = user_team.weekly_user_teams.last.playing11
        end
        # playing11_ids = user_team.weekly_user_teams.last.playing11
        players = user_team.players.where(id: playing11_ids, team_name: [team1, team2])
        players.each do |player|
          player_overall_data = start_points_evaluation(player.name)
          current_matches = create_matches(user_team, player, team1, team2, auction)
          matches << current_matches
          pp_record = create_player_perfomance_record(player, player_overall_data, current_matches&.last&.match_name, user_team)
          players_team_record = player.players_teams.where(team: user_team)&.first
          
          bowled_bonus_points = assign_bowled_and_lbw_points(player)[:bowled_bonus_points]
          lbw_bonus_points = assign_bowled_and_lbw_points(player)[:lbw_bonus_points]
          lbw_and_bowled_bonus_points = bowled_bonus_points + lbw_bonus_points
          
          total_player_points = (pp_record.match_points + pp_record.all_bonus_points + players_team_record.points + lbw_and_bowled_bonus_points) || 0
          players_team_record.update(points: total_player_points)

          current_match_points = (pp_record.match_points + pp_record.all_bonus_points + lbw_and_bowled_bonus_points) || 0
          current_matches&.map { |match| match.update(points: current_match_points) }
          pp_record.update_columns(lbw_bonus: lbw_bonus_points, bowled_bonus: bowled_bonus_points)
          pp_record_ids << pp_record.id
        end

        # STEP-2:- Then Update points of bench players
        if user_team.weekly_user_teams.count > 1
          bench_player_ids = user_team.weekly_user_teams.where("week_start_date <= ?", Date.current)&.last&.bench || user_team.weekly_user_teams.last.bench
        else
          bench_player_ids = user_team.weekly_user_teams.last.bench
        end
        # bench_player_ids = user_team.weekly_user_teams.last.bench
        players = user_team.players.where(id: bench_player_ids, team_name: [team1, team2])
        players.each do |player|
          player_overall_data = start_points_evaluation(player.name)
          current_matches = create_matches(user_team, player, team1, team2, auction)
          matches << current_matches
          pp_record = create_player_perfomance_record(player, player_overall_data, current_matches&.last&.match_name, user_team)
          players_team_record = player.players_teams.where(team: user_team)&.first
          
          bowled_bonus_points = assign_bowled_and_lbw_points(player)[:bowled_bonus_points]
          lbw_bonus_points = assign_bowled_and_lbw_points(player)[:lbw_bonus_points]
          lbw_and_bowled_bonus_points = bowled_bonus_points + lbw_bonus_points
          
          total_player_points = (pp_record.match_points + pp_record.all_bonus_points + players_team_record.bench_points + lbw_and_bowled_bonus_points) || 0

          players_team_record.update(bench_points: total_player_points)

          current_match_points = (pp_record.match_points + pp_record.all_bonus_points + lbw_and_bowled_bonus_points) || 0
          current_matches&.map { |match| match.update(bench_points: current_match_points) }
          pp_record_ids << pp_record.id
        end
      end
    end

    create_match_points
    auctions.each {|auction| update_team_grand_total(auction.teams) }
  end

  private

  def build_bowler_lookup(bowlers_array)
    lookup = {
      by_exact_name: {},
      by_last_name: {},
      by_nickname: {},
      by_id: {}
    }
    
    bowlers_array.each do |bowler|
      id = bowler["id"].to_i
      name = bowler["name"] || ""
      nickname = bowler["nickname"] || ""
      
      lookup[:by_id][id] = bowler
      
      if name.present?
        clean_name = name.downcase.strip
        lookup[:by_exact_name][clean_name] = id
        
        # Add last name
        last_name = clean_name.split(" ").last
        lookup[:by_last_name][last_name] = id unless lookup[:by_last_name][last_name]
      end
      
      if nickname.present?
        clean_nickname = nickname.downcase.strip
        lookup[:by_nickname][clean_nickname] = id
        
        # For nicknames like "M Theekshana", also add "Theekshana"
        nick_last_name = clean_nickname.split(" ").last
        lookup[:by_last_name][nick_last_name] = id unless lookup[:by_last_name][nick_last_name]
      end
    end
    
    lookup
  end

  def extract_bowler_from_dismissal(outdec)
    return nil unless outdec.present?
    
    if outdec.start_with?("b ")
      outdec[2..-1].strip
    elsif outdec.start_with?("lbw b ")
      outdec[6..-1].strip
    else
      nil
    end
  end

  def find_bowler_id_from_name(bowler_name, bowler_lookup, bowlers_array)
    clean_name = bowler_name.downcase.strip
    
    # 1. Try exact match with full name
    return bowler_lookup[:by_exact_name][clean_name] if bowler_lookup[:by_exact_name][clean_name]
    
    # 2. Try match with nickname
    return bowler_lookup[:by_nickname][clean_name] if bowler_lookup[:by_nickname][clean_name]
    
    # 3. Try match with last name
    last_name = clean_name.split(" ").last
    return bowler_lookup[:by_last_name][last_name] if bowler_lookup[:by_last_name][last_name]
    
    # 4. Try partial matching
    bowlers_array.each do |bowler|
      id = bowler["id"].to_i
      name = (bowler["name"] || "").downcase
      nickname = (bowler["nickname"] || "").downcase
      
      # Check if the bowler name contains our search term or vice versa
      if name.include?(clean_name) || clean_name.include?(name) ||
         nickname.include?(clean_name) || clean_name.include?(nickname)
        return id
      end
      
      # Check for abbreviated names like "M Theekshana" matching "Maheesh Theekshana"
      if name.split(" ").any? { |part| part.start_with?(clean_name[0]) } &&
         name.split(" ").last == last_name
        return id
      end
    end
    
    nil
  end

  def update_team_grand_total(teams)
    teams.each do |team|
      grand_total = team.players.map {|p| sum=0; sum+= p.players_teams.where(team:)&.first.points}.sum
      if team.grand_total.negative?
        team.update(grand_total: team.grand_total + grand_total)
      else
        team.update(grand_total:)
      end
    end
  end

  def assign_bowled_and_lbw_points(player)
    bowler_id = player.cricbuzz_player_id.to_i
    return {lbw_bonus_points: 0, bowled_bonus_points: 0} if bowler_id.zero?

    lbw_bonus = 0
    bowled_bonus = 0
    
    @res["scorecard"].each do |innings|
      # Build a lookup table for bowlers in this innings
      bowler_lookup = build_bowler_lookup(innings["bowler"])
      
      innings["batsman"].each do |batsman|
        outdec = batsman["outdec"] || ""
        next if outdec.blank? || outdec == "not out"
        
        # Extract bowler from dismissal description
        bowler_from_desc = extract_bowler_from_dismissal(outdec)
        next unless bowler_from_desc
        
        # Find bowler ID using multiple matching strategies
        found_bowler_id = find_bowler_id_from_name(bowler_from_desc, bowler_lookup, innings["bowler"])
        
        if found_bowler_id == bowler_id
          if outdec.start_with?("b ")
            bowled_bonus += 1
          elsif outdec.start_with?("lbw b ")
            lbw_bonus += 1
          end
        end
      end
    end
    
    lbw_bonus_points = PlayerPerfomacePoint::POINTS_EVALUATION[:lbw_bonus] * lbw_bonus
    bowled_bonus_points = PlayerPerfomacePoint::POINTS_EVALUATION[:bowled_bonus] * bowled_bonus
    
    {lbw_bonus_points:, bowled_bonus_points:}
  end

  def create_player_perfomance_record(player, data, match, team)
    batting_data = data[player.name][:batting]
    bowling_data = data[player.name][:bowling]
    fielding_data = data[player.name][:fielding]
    in_playing11 = playing11_points(player, data)
    
    # In new format, players of the match might not be in the same structure
    is_mom = false
    bonus_mom = 0
    
    PlayerPerfomacePoint.create_record(
      player:,
      team:,
      match:,
      overall_data: data,
      in_playing11:,
      runs: batting_data.present? ? batting_data[:runs] : 0,
      duck: duck?(batting_data),
      balls_faced: batting_data.present? ? batting_data[:balls_faced] : 0,
      fours: batting_data.present? ? batting_data[:fours] : 0,
      sixes: batting_data.present? ? batting_data[:sixes] : 0,
      strike_rate: batting_data.present? ? batting_data[:strike_rate] : 0,
      out_desc: batting_data.present? ? batting_data[:out_desc] : '',
      overs_bowled: bowling_data.present? ? bowling_data[:overs_bowled] : 0,
      wickets: bowling_data.present? ? bowling_data[:wickets] : 0,
      eco: bowling_data.present? ? bowling_data[:economy_rate] : 0,
      maidens: bowling_data.present? ? bowling_data[:maidens] : 0,
      catches: fielding_data[:catches],
      run_outs: fielding_data[:run_outs],
      stumping: fielding_data[:stumpings],
      is_mom:,
      bonus_mom:
    )
  end

  def playing11_points(player, data)
    if data[player.name][:batting].blank? && data[player.name][:bowling].blank? && data[player.name][:fielding].values.all? {|v| v.zero?  }
      points = 0
    else
      points = 4
    end
    points
  end

  def duck?(batting_data)
    return true if (batting_data.present? && batting_data[:runs] == 0 && batting_data[:out_desc].present? && batting_data[:out_desc]!= 'not out')
    false
  end

  def start_points_evaluation(player_name)
    data = {}
    fielding_perfomance = extract_fielding_data(player_name)
    
    @res["scorecard"].each do |scorecard|
      batting_performance = extract_batting_data(scorecard, player_name)
      bowling_performance = extract_bowling_data(scorecard, player_name)
      # Only set if not already set (first innings where player appears)
      data[:batting] = batting_performance if batting_performance.present? && data[:batting].blank?
      data[:bowling] = bowling_performance if bowling_performance.present? && data[:bowling].blank?
    end
    
    data[:fielding] = fielding_perfomance
    { player_name => data }
  end

  def create_wicket_desc(team1, team2)
    desc = []
    match_name = "#{team1} vs #{team2}"
    
    @res['scorecard'].each do |innings|
      innings['batsman'].each do |batsman|
        out_desc = batsman['outdec']
        desc << out_desc if out_desc.present? && out_desc != 'not out'
      end
    end
    
    desc = desc.compact
    WicketDesc.create(match_name:, desc:)
  end

  def create_matches(team, player, team1, team2, auction)
    matches = []
    match_name = "#{team1} vs #{team2}"
    return matches if Match.exists?(match_name:, player:, team:, auction:, match_date: Date.current)

    matches << team.matches.new(match_name:, player:, points: 0, bench_points: 0, auction:, match_date: Date.current) 
    matches
  end

  def create_match_points
    Team.all.each do |team|
      match_name = find_match_teams.join(' vs ')
      if team.matches.blank?
        match_point = MatchPoint.create(match_name:, total_points: 0, total_bench_points: 0, team:, match_date: Date.current)
      else
        total_points = team.matches.where(match_name:, match_date: Date.current).pluck(:points).sum
        total_bench_points = team.matches.where(match_name:, match_date: Date.current).pluck(:bench_points).sum
        match_point = MatchPoint.create(match_name:, total_points:, total_bench_points:,  team:, match_date: Date.current)
      end
      
      puts "MATCHPOINT CREATED WITH NAME:- #{match_name}"
    end
  end

  def extract_batting_data(scorecard, player_name)
    player_record = Player.find_by(name: player_name)
    
    batsman_data = scorecard["batsman"].find do |player|
      player_record.cricbuzz_player_id == player["id"]
    end
    
    if batsman_data.present?
      {
        bat_name: batsman_data["name"],
        balls_faced: batsman_data["balls"],
        runs: batsman_data["runs"],
        fours: batsman_data["fours"],
        sixes: batsman_data["sixes"],
        strike_rate: batsman_data["strkrate"].to_f,
        out_desc: batsman_data["outdec"]
      }
    end
  end

  def extract_bowling_data(scorecard, player_name)
    player_record = Player.find_by(name: player_name)
    bowler_data = scorecard["bowler"].find do |bowler|
      player_record.cricbuzz_player_id == bowler["id"]
    end
    
    if bowler_data.present?
      {
        bolwer_name: bowler_data["name"],
        overs_bowled: bowler_data["overs"].to_f,
        wickets: bowler_data["wickets"],
        maidens: bowler_data["maidens"],
        economy_rate: bowler_data["economy"].to_f
      }
    end
  end

  def extract_fielding_data(player_name)
    return { catches: 0, run_outs: 0, stumpings: 0 } if player_name.nil? || player_name.empty?

    player = Player.find_by(name: player_name)
    return { catches: 0, run_outs: 0, stumpings: 0 } if player.nil?

    target_player_id = player.cricbuzz_player_id.to_i
    return { catches: 0, run_outs: 0, stumpings: 0 } if target_player_id.zero?

    catches = 0
    run_outs = 0
    stumpings = 0

    @res["scorecard"].each do |innings|
      innings["batsman"].each do |batsman|
        outdec = batsman["outdec"] || ""
        next unless outdec.present? && outdec != "not out"

        # Check for catches
        if outdec.start_with?('c ')
          # Format: "c Fielder b Bowler" or "c and b Bowler"
          if outdec.include?(' b ')
            parts = outdec.split(' b ')
            fielder_part = parts[0]
            
            if fielder_part.start_with?('c ') && fielder_part != 'c and'
              fielder_name = fielder_part[2..-1].strip
              # Find the fielder in the batsman array (from either innings)
              fielder = find_player_by_name_in_scorecard(fielder_name)
              catches += 1 if fielder && fielder["id"].to_i == target_player_id
            elsif fielder_part == 'c and'
              # Caught and bowled - check if player is the bowler
              bowler_name = parts[1].strip
              bowler = find_player_by_name_in_scorecard(bowler_name)
              catches += 1 if bowler && bowler["id"].to_i == target_player_id
            end
          end
        end
        
        # Check for run outs
        if outdec.start_with?('run out')
          # Extract names from parentheses if available
          if outdec.include?('(') && outdec.include?(')')
            start_idx = outdec.index('(') + 1
            end_idx = outdec.index(')')
            fielders_text = outdec[start_idx...end_idx]
            
            # Clean up and split properly
            # Remove extra spaces and normalize separators
            fielders_text = fielders_text.gsub(' and ', '/').gsub(' / ', '/').gsub('  ', ' ')
            fielders = fielders_text.split('/').map(&:strip)
            
            fielders.each do |fielder_name|
              fielder = find_player_by_name_in_scorecard(fielder_name)
              run_outs += 1 if fielder && fielder["id"].to_i == target_player_id
            end
          end
        end
        
        # Check for stumpings
        if outdec.start_with?('st ')
          if outdec.include?(' b ')
            parts = outdec.split(' b ')
            keeper_part = parts[0]
            keeper_name = keeper_part[3..-1].strip
            keeper = find_player_by_name_in_scorecard(keeper_name)
            stumpings += 1 if keeper && keeper["id"].to_i == target_player_id
          end
        end
      end
    end
    {
      catches: catches,
      run_outs: run_outs,
      stumpings: stumpings
    }
  end

  def find_player_by_name_in_scorecard(player_name)
    return nil if player_name.blank?
    
    # Search in both innings of the scorecard
    @res["scorecard"].each do |innings|
      # Search in batsman array
      player = innings["batsman"].find do |p|
        p["name"] == player_name || p["nickname"] == player_name
      end
      return player if player
      
      # Search in bowler array if not found in batsman
      player = innings["bowler"].find do |p|
        p["name"] == player_name || p["nickname"] == player_name
      end
      return player if player
    end
    
    nil
  end

  def compare_names(name1, name2)
    return false if name1.nil? || name2.nil?
    
    name1_down = name1.downcase.strip
    name2_down = name2.downcase.strip
    
    # Exact match
    return true if name1_down == name2_down
    
    # Partial match (last name only)
    name1_parts = name1_down.split
    name2_parts = name2_down.split
    
    return true if name1_parts.last == name2_parts.last
    
    # Check for abbreviated names
    if name2_down.include?('.')
      # Format like "M.Levitt" for "Michael Levitt"
      name1_initials = name1_parts.map { |part| part[0] }.join('.')
      return true if name2_down.start_with?(name1_initials.downcase)
    end
    
    false
  end

  def safegurad_stat(data, category, stat)
    data.values.first[category]&.dig(stat) || 0
  end
end
