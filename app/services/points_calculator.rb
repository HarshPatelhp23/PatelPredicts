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

  # sample match_id =>  101626
  # match_id = 101617 for run out
  def initialize(match_ids)
    @auctions = Auction.all
    # @match_id = match_id.is_a?(Array) ? match_id.to_param : match_id
    # @res = fetch_scorecard(@match_id)
    # store_response(match_data: @res)
    #this is demo res for testing purpose only
    # @res = Responses::ScorecardResponse.demo_res
    # NZ VS PAK => SeriesMatchResponse.find(126).match_data
    # BAN VS IND => SeriesMatchResponse.find(127).match_data
    # RSA VS AFG => SeriesMatchResponse.find(129).match_data
    # @res = SeriesMatchResponse.find(5).match_data
    
    #uncomment me for live use
    match_ids.each do |match_id|
      @res = fetch_scorecard(match_id)
      store_response(match_data: @res)
    end
  end

  def fetch_scorecard(match_id)
    end_point = "/mcenter/v1/#{match_id}/hscard"
    response = self.class.get(end_point, headers: HEADERS)
    parse_response(response) #"matchHeader"
  end

  def find_match_teams
  	t1 = res['scoreCard'].first.fetch('batTeamDetails').fetch('batTeamShortName')
  	t2 = res['scoreCard'].first.fetch('bowlTeamDetails').fetch('bowlTeamShortName')
  	[t1,t2]
  end

  def calculate_total_points
  	team1, team2 = find_match_teams
  	matches = []
    pp_record_ids = []
  	create_wicket_desc(team1, team2)
  	auctions.each do |auction|
  		auction.teams.each do |user_team|
  			# UNCOMMENT ME ONCE FIRST WEEK POINTS UPDATE IS COMPLETE
  			if user_team.weekly_user_teams.count > 1
  				playing11_ids = user_team.weekly_user_teams.where("week_end_date >= ?", Date.current)&.first&.playing11 || user_team.weekly_user_teams.last.playing11
  			else
  				playing11_ids = user_team.weekly_user_teams.last.playing11
  			end
        # playing11_ids = user_team.weekly_user_teams.where(week: 2)&.first.playing11
				players = user_team.players.where(id: playing11_ids, team_name: [team1, team2])
				players.each do |player|
					player_overall_data = start_points_evaluation(player.name, user_team, playing11_ids)
          match_date = set_match_details("#{team1} vs #{team2}")[:match_date]
					current_matches = create_matches(user_team, player, team1, team2, auction, match_date)
					matches << current_matches
					pp_record = create_player_perfomance_record(player, player_overall_data,current_matches&.last&.match_name, user_team)
					players_team_record = player.players_teams.where(team: user_team)&.first
					# add current match points + current_match_bonus_points + existing player points + bowled_and_lbw_bonus_points
          bowled_bonus_points = assign_bowled_and_lbw_points(player)[:bowled_bonus_points]
          lbw_bonus_points = assign_bowled_and_lbw_points(player)[:lbw_bonus_points]
          lbw_and_bowled_bonus_points = bowled_bonus_points + lbw_bonus_points
					total_player_points = (pp_record.match_points + pp_record.all_bonus_points + players_team_record.points + lbw_and_bowled_bonus_points) || 0
					players_team_record.update(points: total_player_points)

					current_match_points = (pp_record.match_points + pp_record.all_bonus_points + lbw_and_bowled_bonus_points) || 0
					current_matches&.map { |match| match.update(points: current_match_points) }
          pp_record.update_columns(lbw_bonus: lbw_bonus_points, bowled_bonus: bowled_bonus_points)
          pp_record_ids << pp_record.id
					#THIS LINE IS UNDER TESTING
          # pp_record.assign_bowled_and_lbw_points(current_matches.last.match_name, user_team)
					# pp_record.update_all_bonus_point_fields
				end
			end
			# auctions.each do |auction|
			# 	auction.teams.each do |team|
			# 		match = matches.flatten&.first&.match_name
			# 		team.player_perfomace_points.where(match:).find_each do |pp_record|
			# 			pp_record.assign_bowled_and_lbw_points(match)
			# 		end
			# 	end
			# end
		end
    # pp_records = PlayerPerfomacePoint.where(match: find_match_teams.join(' vs ')).where("overs_bowled > ?", 0)
    # pp_records.each do |pp_record|
    #   next if pp_record.team.matches.blank?

    #   pp_record.assign_bowled_and_lbw_points
    # end

		create_match_points
		auctions.each {|auction| update_team_grand_total(auction.teams) }
  end

  private

  def create_match_points
  	Team.all.each do |team|
      next if team.matches.blank?

  		# match_name = team.matches.order(created_at: :desc).first.match_name
      match_name = find_match_teams.join(' vs ')
  		total_points = team.matches.where(match_name:).pluck(:points).sum
  		match_point = MatchPoint.create(match_name:, total_points:, team:)
      puts "+++++++++++++++++++++++++++++++++++++++++++++++"
      puts "+++++++++++++++++++++++++++++++++++++++++++++++"
      puts "+++++++++++++++++++++++++++++++++++++++++++++++"
      puts "+++++++++++++++++++++++++++++++++++++++++++++++"
      puts "+++++++++++++++++++++++++++++++++++++++++++++++"
      puts "+++++++++++++++++++++++++++++++++++++++++++++++"
      puts "MATCHPOINT CREATED WITH NAME:- #{match_name}"
      puts "+++++++++++++++++++++++++++++++++++++++++++++++"
      puts "+++++++++++++++++++++++++++++++++++++++++++++++"
      puts "+++++++++++++++++++++++++++++++++++++++++++++++"
      puts "+++++++++++++++++++++++++++++++++++++++++++++++"
      puts "+++++++++++++++++++++++++++++++++++++++++++++++"
      puts "+++++++++++++++++++++++++++++++++++++++++++++++"
      puts "+++++++++++++++++++++++++++++++++++++++++++++++"
      puts "+++++++++++++++++++++++++++++++++++++++++++++++"
      puts "+++++++++++++++++++++++++++++++++++++++++++++++"
      puts "+++++++++++++++++++++++++++++++++++++++++++++++"
      puts "+++++++++++++++++++++++++++++++++++++++++++++++"
  	end
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
    bowler_id = player.cricbuzz_player_id.to_s
    lbw_bonus = 0
    bowled_bonus = 0
    
    res["scoreCard"].each do |innings|
      innings["batTeamDetails"]["batsmenData"].each do |_key, batsman|
        next unless batsman["wicketCode"].in?(%w[BOWLED LBW])
        next unless batsman["bowlerId"].to_s == bowler_id
        
        if batsman["wicketCode"] == "LBW"
          lbw_bonus += 1
        else
          bowled_bonus += 1
        end
      end
    end
    
    # Calculate bonus points
    lbw_bonus_points = PlayerPerfomacePoint::POINTS_EVALUATION[:lbw_bonus] * lbw_bonus
    bowled_bonus_points = PlayerPerfomacePoint::POINTS_EVALUATION[:bowled_bonus] * bowled_bonus
    
    # Update performance record
    {lbw_bonus_points:, bowled_bonus_points:}
  end

  def create_player_perfomance_record(player, data, match, team)
  	batting_data = data[player.name][:batting]
  	bowling_data = data[player.name][:bowling]
  	fielding_data = data[player.name][:fielding]
    in_playing11 = playing11_points(player, data)
    is_mom = (res["matchHeader"]["playersOfTheMatch"].first["id"] == player.cricbuzz_player_id ||res["matchHeader"]["playersOfTheMatch"].first["name"] == player.name || res["matchHeader"]["playersOfTheMatch"].first["name"].casecmp?(player.name) || res["matchHeader"]["playersOfTheMatch"].first["name"].match?(/\A#{Regexp.escape(player.name)}\z/i)) ? true : false
    bonus_mom = is_mom ? PlayerPerfomacePoint::POINTS_EVALUATION[:bonus_mom] : 0
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

  def start_points_evaluation(player_name, team, playing11_ids)
  	data = {}
  	# batting_performance, bowling_performance = nil
    fielding_perfomance = extract_fielding_data(player_name)
    # in_playing = calculate_playing11_points(res['scoreCard'], player_name, team, playing11_ids)
  	res["scoreCard"].flat_map do |scorecard|
    	batting_performance = extract_batting_data(scorecard, player_name)
    	bowling_performance = extract_bowling_data(scorecard, player_name)
    	data[:batting] = batting_performance if data[:batting].blank?
    	data[:bowling] = bowling_performance if data[:bowling].blank?
    	data[:fielding] = fielding_perfomance
    	# data[:in_playing11] = in_playing
    end    
    { player_name => data }
  end

  def create_wicket_desc(team1, team2)
  	desc = []
  	match_name = "#{team1} vs #{team2}"
  	res['scoreCard'].each do |innings|
		  batsmen_data = innings['batTeamDetails']['batsmenData']

		  batsmen_data.each do |_key, batsman|
		    out_desc = batsman['outDesc']
		    desc << out_desc if out_desc
		  end
		end
		desc = desc.compact
  	WicketDesc.create(match_name:, desc:)
  end

  def create_matches(team, player, team1, team2, auction, match_date)
  	matches = []
  	match_name = "#{team1} vs #{team2}"
  	return if Match.exists?(match_name:, player:, team:, auction:, match_date:)

  	matches << team.matches.new(match_name:, player:, points: 0, auction:) 
  	matches
  end

  def extract_batting_data(scorecard, player_name)
  	# Extract batsmen data
    player_record = Player.find_by(name: player_name)
  	batsman_data = scorecard["batTeamDetails"]["batsmenData"].values.find do |player|
	    player_record.cricbuzz_player_id == player["batId"] || player_name.downcase.include?(player["batName"]&.downcase) || compare_short_name(player_name, player["batShortName"])
	    # player_name.downcase.include?(player["batName"]&.downcase) || player_name.downcase.include?(player["batShortName"]&.downcase)
	  end
	  if batsman_data.present?
	    batting_performance = {
	      bat_name: batsman_data["batName"],
	      balls_faced: batsman_data["balls"],
	      runs: batsman_data["runs"],
	      fours: batsman_data["fours"],
	      sixes: batsman_data["sixes"],
	      strike_rate: batsman_data["strikeRate"],
	      out_desc: batsman_data["outDesc"]
	    }
	  end
  end

  def extract_bowling_data(scorecard, player_name)
  	# Extract bowler data (assuming bowler data is also available in a similar format, you can adjust this as needed)
    player_record = Player.find_by(name: player_name)
	  bowler_data = scorecard["bowlTeamDetails"]["bowlersData"].values.find do |bowler|
	    # bowler["bowlName"] == player_name
	    player_record.cricbuzz_player_id == bowler["bowlerId"] || player_name.downcase.include?(bowler["bowlName"]&.downcase) || compare_short_name(player_name, bowler["bowlShortName"])
	    # player_name.downcase.include?(bowler["bowlName"]&.downcase) || player_name.downcase.include?(bowler["bowlShortName"]&.downcase)
	  end
  	if bowler_data.present?
	    bowling_performance = {
	      bolwer_name: bowler_data["bowlName"],
	      overs_bowled: bowler_data["overs"],
	      wickets: bowler_data["wickets"],
	      maidens: bowler_data["maidens"],
	      economy_rate: bowler_data["economy"]
	    }
	  end
  end

  def extract_fielding_data(player_name)
  # Ensure we have a valid player name
    return { catches: 0, run_outs: 0, stumpings: 0, total: 0 } if player_name.nil? || player_name.empty?

    # Get player record to access cricbuzz_player_id
    player = Player.find_by(name: player_name)
    return { catches: 0, run_outs: 0, stumpings: 0, total: 0 } if player.nil?

    if player.cricbuzz_player_id.nil?
      puts "++++++++++++++++++++++++++++++++"
      puts "++++++++++++++++++++++++++++++++"
      puts "++++++++++++++++++++++++++++++++"
      puts "++++++++++++++++++++++++++++++++"
      puts "CRICBUZZ-PLAYERID NOT FOUND , NOW UPDATING IT MANUALLY BY NAME"
      puts "++++++++++++++++++++++++++++++++"
      puts "++++++++++++++++++++++++++++++++"
      puts "++++++++++++++++++++++++++++++++"
      puts "++++++++++++++++++++++++++++++++"
      update_fielding_points_by_name(player_name)
    end

    # Initialize counters
    catches = 0
    run_outs = 0
    stumpings = 0

    # Process each innings in the scorecard
    res["scoreCard"].each do |innings|
      # Check batsmen data for fielding contributions
      batsmen_data = innings["batTeamDetails"]["batsmenData"]
      batsmen_data.each do |_key, batsman|
        next unless batsman["outDesc"].present? && batsman["outDesc"] != "not out"

        # Check wicket type and fielders
        case batsman["wicketCode"]
        when "CAUGHT", "CAUGHT_BEHIND"
          # Check if our player was the fielder
          if [batsman["fielderId1"], batsman["fielderId2"], batsman["fielderId3"]].include?(player.cricbuzz_player_id)
            catches += 1
          end
        when "RUNOUT"
          # Check if our player was involved in the run out
          if [batsman["fielderId1"], batsman["fielderId2"], batsman["fielderId3"]].include?(player.cricbuzz_player_id)
            run_outs += 1
          end
        when "STUMPED"
          # Check if our player was the wicketkeeper
          if [batsman["fielderId1"], batsman["fielderId2"], batsman["fielderId3"]].include?(player.cricbuzz_player_id)
            stumpings += 1
          end
        end
      end
    end

    puts "Catches: #{catches.inspect}"
    puts "Run-outs: #{run_outs.inspect}"
    puts "Stumpings: #{stumpings.inspect}"
    puts "Player: #{player_name.inspect}"

    {
      catches: catches,
      run_outs: run_outs,
      stumpings: stumpings
    }
  end

  def update_fielding_points_by_name(player_name)
    # Ensure we have a valid player name
    return { catches: 0, run_outs: 0, stumpings: 0, total: 0 } if player_name.nil? || player_name.empty?
    
    # Safely get dismissal descriptions for production
    wicket_desc = WicketDesc.last
    return { catches: 0, run_outs: 0, stumpings: 0, total: 0 } if wicket_desc.nil?
    
    out_desc = wicket_desc.desc&.compact_blank || []
    
    # Initialize counters
    catches = 0
    run_outs = 0
    stumpings = 0
    
    # Add debug info to track matches
    debug_info = []
    
    # Process each dismissal description
    out_desc.each do |desc|
      # Skip if description is nil or empty
      next if desc.nil? || desc.empty?
      
      # Handle catches
      if desc.start_with?('c ')
        if desc.include?(' b ')
          # Regular catch: "c Fielder b Bowler"
          b_index = desc.index(' b ')
          next if b_index.nil?
          
          fielder_name = desc[2..(b_index - 1)]
          if name_matches?(fielder_name, player_name)
            catches += 1
            debug_info << "Regular catch by #{player_name}: #{desc}"
          end
        end
      end
      
      # Handle caught and bowled separately for clarity
      if desc.start_with?('c and b ')
        # Caught and bowled: "c and b Bowler"
        bowler_name = desc.sub('c and b ', '').strip
        
        if name_matches?(bowler_name, player_name)
          catches += 1
          debug_info << "Caught and bowled by #{player_name}: #{desc}"
        end
      end
      
      # Handle run outs
      if desc.start_with?('run out')
        # Extract name(s) from parentheses
        if desc.include?('(') && desc.include?(')')
          open_index = desc.index('(')
          close_index = desc.index(')')
          
          next if open_index.nil? || close_index.nil? || open_index >= close_index
          
          fielders_text = desc[open_index + 1...close_index]
          next if fielders_text.nil?
          
          # Split on both slash and 'and' to handle different formats
          fielders = fielders_text.gsub(' and ', '/').split('/')
          
          fielders.each do |fielder|
            fielder_cleaned = fielder.to_s.strip
            if name_matches?(fielder_cleaned, player_name)
              run_outs += 1
              debug_info << "Run out by #{player_name}: #{desc}"
            end
          end
        end
      end
      
      # Handle stumpings
      if desc.start_with?('st ')
        # Format: "st Wicketkeeper b Bowler"
        b_index = desc.index(' b ')
        next if b_index.nil?
        
        keeper_name = desc[3..(b_index - 1)]
        if name_matches?(keeper_name, player_name)
          stumpings += 1
          debug_info << "Stumping by #{player_name}: #{desc}"
        end
      end
    end
    
    puts "Catches: #{catches.inspect}"
    puts "Run-outs: #{run_outs.inspect}"
    puts "Stumpings: #{stumpings.inspect}"
    puts "Player: #{player_name.inspect}"
    {
      catches: catches,
      run_outs: run_outs,
      stumpings: stumpings
    }
  end

  # def extract_fielding_data(player_name)
  #   # Ensure we have a valid player name
  #   return { catches: 0, run_outs: 0, stumpings: 0, total: 0 } if player_name.nil? || player_name.empty?

  #   # Fetch player record and other names
  #   player_record = Player.find_by(name: player_name)
  #   player_other_names = player_record&.other_names || []

  #   # Safely get dismissal descriptions for production
  #   wicket_desc = WicketDesc.last
  #   return { catches: 0, run_outs: 0, stumpings: 0, total: 0 } if wicket_desc.nil?

  #   out_desc = wicket_desc.desc&.compact_blank || []

  #   # Initialize counters
  #   catches = 0
  #   run_outs = 0
  #   stumpings = 0

  #   # Add debug info to track matches
  #   debug_info = []

  #   # Process each dismissal description
  #   out_desc.each do |desc|
  #     # Skip if description is nil or empty
  #     next if desc.nil? || desc.empty?

  #     # Check for matches with player_name or player_other_names
  #     if name_matches?(desc, player_name) || player_other_names.any? { |other_name| name_matches?(desc, other_name) }
  #       # Handle catches
  #       if desc.start_with?('c ')
  #         if desc.include?(' b ')
  #           # Regular catch: "c Fielder b Bowler"
  #           b_index = desc.index(' b ')
  #           next if b_index.nil?

  #           fielder_name = desc[2..(b_index - 1)]
  #           if name_matches?(fielder_name, player_name) || player_other_names.any? { |other_name| name_matches?(fielder_name, other_name) }
  #             catches += 1
  #             debug_info << "Regular catch by #{player_name}: #{desc}"
  #           end
  #         end
  #       end

  #       # Handle caught and bowled separately for clarity
  #       if desc.start_with?('c and b ')
  #         # Caught and bowled: "c and b Bowler"
  #         bowler_name = desc.sub('c and b ', '').strip

  #         if name_matches?(bowler_name, player_name) || player_other_names.any? { |other_name| name_matches?(bowler_name, other_name) }
  #           catches += 1
  #           debug_info << "Caught and bowled by #{player_name}: #{desc}"
  #         end
  #       end

  #       # Handle run outs
  #       if desc.start_with?('run out')
  #         # Extract name(s) from parentheses
  #         if desc.include?('(') && desc.include?(')')
  #           open_index = desc.index('(')
  #           close_index = desc.index(')')

  #           next if open_index.nil? || close_index.nil? || open_index >= close_index

  #           fielders_text = desc[open_index + 1...close_index]
  #           next if fielders_text.nil?

  #           # Split on both slash and 'and' to handle different formats
  #           fielders = fielders_text.gsub(' and ', '/').split('/')
  #           # byebug if player_name == 'Deepak Chahar'
  #           # byebug if player_record.id == 177
  #           fielders.each do |fielder|
  #             fielder_cleaned = fielder.to_s.strip
  #             if name_matches?(fielder_cleaned, player_name) || player_other_names.any? { |other_name| name_matches?(fielder_cleaned, other_name) }
  #               run_outs += 1
  #               debug_info << "Run out by #{player_name}: #{desc}"
  #             end
  #           end
  #         end
  #       end

  #       # Handle stumpings
  #       if desc.start_with?('st ')
  #         # Format: "st Wicketkeeper b Bowler"
  #         b_index = desc.index(' b ')
  #         next if b_index.nil?

  #         keeper_name = desc[3..(b_index - 1)]
  #         if name_matches?(keeper_name, player_name) || player_other_names.any? { |other_name| name_matches?(keeper_name, other_name) }
  #           stumpings += 1
  #           debug_info << "Stumping by #{player_name}: #{desc}"
  #         end
  #       end
  #     end
  #   end

  #   puts "Catches: #{catches.inspect}"
  #   puts "Run-outs: #{run_outs.inspect}"
  #   puts "Stumpings: #{stumpings.inspect}"
  #   puts "Player: #{player_name.inspect}"
  #   {
  #     catches: catches,
  #     run_outs: run_outs,
  #     stumpings: stumpings
  #   }
  # end

def name_matches?(name_in_desc, player_name)
    # Guard against nil values
    player_record = Player.find_by(name: player_name)
    player_other_names = player_record.other_names
    return false if name_in_desc.nil? || player_name.nil?
    
    # Convert both names to lowercase for case-insensitive comparison
    player_name_lower = player_name.to_s.downcase.strip
    name_in_desc_lower = name_in_desc.to_s.downcase.strip
    
    # Extract player name parts
    player_name_parts = player_name_lower.split(/\s+/)
    name_in_desc_parts = name_in_desc_lower.split(/\s+/)
    
    # Check for exact match
    return true if name_in_desc_lower == player_name_lower

    return true if player_other_names.any? { |name| name.downcase.include?(name_in_desc_lower) }

    if name_in_desc.include?('run out ')
      players = name_in_desc.split('run out ').last
      player1, player2 = players.split('/')
      player1.gsub('(','').gsub(')','')
      player2.gsub('(','').gsub(')','')
      return true if player_other_names.any? { |name| name.downcase.include?(player1.downcase) } || player_other_names.any? { |name| name.downcase.include?(player2.downcase) }
    end

    if name_in_desc.include?('run out ')
      players = name_in_desc.split('run out ').last
      player1, player2 = players.split('/')
      player1.gsub('(','').gsub(')','')
      player2.gsub('(','').gsub(')','')
      return true if player1.downcase.include?(player_name.downcase) || player2.downcase.include?(player_name.downcase)
    end
    
    # For players with multiple names (first and last)
    if player_name_parts.length > 1
      # Match last name only if it's a unique identifier
      # This is crucial for players like "Marnus Labuschagne" where "Labuschagne" is distinctive
      if name_in_desc_lower == player_name_parts.last
        return true 
      end
      
      # Check for first name match only if it's distinct enough
      if name_in_desc_lower == player_name_parts.first
        return true
      end
    elsif player_name_parts.length == 1
      # For single-word names, direct comparison
      return true if name_in_desc_lower == player_name_lower
    end
    
    # Handle abbreviated names (like H.Pandya for Hardik Pandya)
    if name_in_desc_lower.include?('.') && player_name_parts.length > 1 && !player_name_parts.first.empty?
      abbr_initial = player_name_parts.first[0].downcase
      last_name = player_name_parts.last.downcase
      abbr_pattern = "#{abbr_initial}.#{last_name}"
      return true if name_in_desc_lower == abbr_pattern
    end
    
    false
  end


  # def calculate_playing11_points(scorecard, player, team, playing11_ids)
  # 	playing_22 = []
  # 	players_in_team = team.players.where(id: playing11_ids)
  #                                 .pluck(:id, :name)
  #                                 .to_h { |id, name| [name.downcase, name] }
  # 	for i in (0..(scorecard.length - 1)) do
	 #  	fielder_data = scorecard[i]['batTeamDetails']['batsmenData'].each do |_k, v|
	 #  		# player_in_db = team.players.where(id: playing11_ids).where("name ILIKE ?", "%#{v['batName']}%")&.first&.name
	 #  		bat_name = v['batName'].downcase
	 #  		player_in_db = players_in_team.find { |p_name, _| p_name.include?(bat_name) }&.last
	 #  		playing_22 << (player_in_db || v['batName'])
		#  	end
		# end
  # 	player_first_name, player_last_name = player.split(' ', 2)
	 #  player_last_name ||= '' # Handle cases where the player has only one name

	 #  # Find the best match based on the custom logic
	 #  amatch_matcher = Amatch::Levenshtein.new(player_last_name)
	 #  best_match = playing_22.min_by do |name|
	 #    name_first_name, name_last_name = name.split(' ', 2)
	 #    name_last_name ||= ''

	 #    if player_first_name.casecmp(name_first_name).zero?
	 #      amatch_matcher.match(name_last_name)
	 #    else
	 #      Amatch::Levenshtein.new(player).match(name)
	 #    end
	 #  end

	 #  # Calculate similarity based on the best match
	 #  best_match_first_name, best_match_last_name = best_match.split(' ', 2)
	 #  best_match_last_name ||= ''

	 #  if player_first_name.casecmp(best_match_first_name).zero?
	 #    similarity = 1 - (amatch_matcher.match(best_match_last_name).to_f / [player_last_name.length, best_match_last_name.length].max)
	 #  else
	 #    similarity = 1 - (Amatch::Levenshtein.new(player).match(best_match).to_f / [player.length, best_match.length].max)
	 #  end
		# points = (best_match.present? && similarity > 0.5) ? PlayerPerfomacePoint::POINTS_EVALUATION[:in_playing11] : 0
		# points
  # end

  # def calculate_batting_points(data)
  # 	res_runs = safegurad_stat(data, :batting, :runs)
  # 	res_fours = safegurad_stat(data, :batting, :fours)
  # 	res_sixes = safegurad_stat(data, :batting, :sixes)
  # 	runs = evaluate_points[:runs] * res_runs
  # 	fours = evaluate_points[:fours] * res_fours
  # 	sixes = evaluate_points[:sixes] * res_sixes
  # 	duck_dissmissal_penalty = res_runs.zero? ? -10 : 0
  # 	strike_rate = evaluate_points[:strike_rate] *  data.values.first[:batting]&.dig(:strike_rate)
  # 	runs + fours + sixes + duck_dissmissal_penalty
  # end

  # def calculate_bowling_points(data)
  # 	res_wickets = safegurad_stat(data, :bowling, :wickets)
  # 	res_maidens = safegurad_stat(data, :bowling, :maidens)
  # 	wickets = (evaluate_points[:wickets] * res_wickets) + wicket_bonus_points(res_wickets)
  # 	maidens = evaluate_points[:maidens] * res_maidens
  # 	economy_rate = data.values.first[:batting]&.dig(:economy_rate)
  # 	eco = calculate_eco_points(economy_rate)
  # 	wickets + maidens + eco + lbw_and_bowled_bonus(data.values.first[:bowling])
  # end

 #  def calculate_eco_points(economy_rate)
	#   economy_rate = economy_rate.is_a?(Integer) ? economy_rate : economy_rate.to_i
	#   points = case
	#            when economy_rate < 6
	#              4
	#            when economy_rate >= 6 && economy_rate < 7
	#              2
	#            when economy_rate >= 7 && economy_rate <= 10
	#              0
	#            when economy_rate > 10 && economy_rate <=12
	#              -2
	#            when economy_rate > 12
	#            	 -4
	#            else
	#              0
	#            end
	# end

  # def lbw_and_bowled_bonus(bowling_data)
  # 	0
  # end

  # def wicket_bonus_points(wickets)
  # 	points = case
  # 					 when wickets == 3
  # 					   5
  # 					 when wickets == 4
  # 					 	 8
  # 					 when wickets >= 5
  # 					 	 10
  # 					 else
  # 					 	 0
  # 					 end
  # 	points
  # end

  # def calculate_fielding_points(fielding_data)
  # 	catches = fielding_data[:catches]
  # 	run_outs = fielding_data[:run_outs]
  # 	(evaluate_points[:catch] * catches) + (evaluate_points[:run_out] * run_outs)
  # end

  def compare_short_name(player_name, short_name)
  	return true if player_name.downcase == short_name.downcase

  	false
  end

  def safegurad_stat(data, category, stat)
  	data.values.first[category]&.dig(stat) || 0
  end
end
