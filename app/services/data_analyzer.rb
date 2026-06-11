# frozen_string_literal: true

require 'csv'

class DataAnalyzer
  attr_accessor :csv_files

  # Initialize the class with an array of CSV files
  # def initialize(*csv_files)
  #   @csv_files = csv_files
  # end

  def fetch_head_to_head_stats(player1, player2, *prefixes)
    player1_data = { batting: [], bowling: [] }
    player2_data = { batting: [], bowling: [] }

    prefixes.each do |prefix|
      batting_file = Rails.root.join('lib', 'spl_data', "#{prefix}_batting.csv")
      bowling_file = Rails.root.join('lib', 'spl_data', "#{prefix}_bowling.csv")

      # Process batting
      if File.exist?(batting_file)
        CSV.foreach(batting_file, headers: true) do |row|
          player_name = row['PlayerName']
          data = generate_output_hash_for_batting(row)

          player1_data[:batting] << data if player_name.downcase == player1.downcase
          player2_data[:batting] << data if player_name.downcase == player2.downcase
        end
      end

      # Process bowling
      if File.exist?(bowling_file)
        CSV.foreach(bowling_file, headers: true) do |row|
          player_name = row['Player']
          data = generate_output_hash_for_bowling(row)

          player1_data[:bowling] << data if player_name.downcase == player1.downcase
          player2_data[:bowling] << data if player_name.downcase == player2.downcase
        end
      end
    end

    {
      player1: {
        name: player1,
        batting: player1_data[:batting],
        bowling: player1_data[:bowling]
      },
      player2: {
        name: player2,
        batting: player2_data[:batting],
        bowling: player2_data[:bowling]
      }
    }
  end


  def self.extract_cricket_stats(raw_data)
    matches = []
    current_match = nil
    current_over = nil
    current_bowler = nil
    batsmen_on_pitch = []
    
    # Parse each line of the raw data
    raw_data.split("\n").each do |line|
      line.strip!
      
      # Detect new match
      if line.start_with?('MATCH-')
        current_match = {
          id: line.gsub('MATCH-', '').to_i,
          innings: [],
          current_innings: { overs: [], batsmen: {}, bowlers: {} }
        }
        matches << current_match
        next
      end
      
      # Skip empty lines and profile images
      next if line.empty? || line.include?('profileImageimage') || line.include?('NEXT')
      
      # Detect end of over
      if line.start_with?('END OF OVER')
        current_over = nil
        current_bowler = nil
        next
      end
      
      # Detect over header (e.g., "5.0")
      if line =~ /^\d+\.\d+$/
        over_parts = line.split('.')
        current_over = {
          number: over_parts[0].to_i,
          ball: over_parts[1].to_i,
          deliveries: []
        }
        current_match[:current_innings][:overs] << current_over
        next
      end
      
      # Detect bowler information
      if line.include?('Right-arm') || line.include?('Left-arm') || line.include?('Slow')
        bowler_info = line.split("\n")
        bowler_name = bowler_info[0]
        bowler_type = bowler_info[1]
        
        # Extract bowler stats if available
        if bowler_info.size > 2
          stats = bowler_info[2..-1].each_with_object({}) do |stat, hash|
            key, value = stat.split(':').map(&:strip)
            hash[key.downcase.gsub(' ', '_').to_sym] = value
          end
        end
        
        current_bowler = {
          name: bowler_name,
          type: bowler_type,
          stats: stats || {}
        }
        
        current_match[:current_innings][:bowlers][bowler_name] ||= current_bowler
        next
      end
      
      # Detect batsman information
      if line.include?('RHB') || line.include?('LHB')
        batsman_info = line.split("\n")
        batsman_name = batsman_info[0]
        batting_hand = batsman_info[1]
        
        # Extract batsman stats if available
        if batsman_info.size > 2
          stats = batsman_info[2..-1].each_with_object({}) do |stat, hash|
            key, value = stat.split(':').map(&:strip)
            hash[key.downcase.gsub(' ', '_').to_sym] = value
          end
        end
        
        batsman = {
          name: batsman_name,
          hand: batting_hand,
          stats: stats || {}
        }
        
        current_match[:current_innings][:batsmen][batsman_name] ||= batsman
        batsmen_on_pitch << batsman_name unless batsmen_on_pitch.include?(batsman_name)
        next
      end
      
      # Process ball delivery
      if current_over && current_bowler && line.include?(' to ')
        parts = line.split(',')
        delivery_part = parts[0]
        outcome_part = parts[1..-1].join(',').strip
        
        # Parse delivery info (e.g., "Suraj 2 to Yash Agrawal")
        bowler, batsman = delivery_part.split(' to ').map(&:strip)
        
        # Parse outcome (e.g., "OUT Bowled", "1 run", "SIX")
        runs = 0
        extras = 0
        wicket = false
        wicket_type = nil
        wicket_details = nil
        
        if outcome_part.include?('OUT')
          wicket = true
          wicket_parts = outcome_part.split('OUT').last.strip.split(',')
          wicket_type = wicket_parts[0].strip
          wicket_details = wicket_parts[1..-1].join(',').strip if wicket_parts.size > 1
          
          # Extract batter's stats from dismissal (e.g., "Yash Agrawal b Suraj 2 (6r 5b 0x4s 1x6s SR: 120.00)")
          if outcome_part =~ /\((\d+)r (\d+)b (\d+)x4s (\d+)x6s SR: ([\d.]+)\)/
            batsman_stats = {
              runs: $1.to_i,
              balls: $2.to_i,
              fours: $3.to_i,
              sixes: $4.to_i,
              strike_rate: $5.to_f
            }
            
            # Update batsman's stats in the match
            if current_match[:current_innings][:batsmen][batsman]
              current_match[:current_innings][:batsmen][batsman].merge!(batsman_stats)
            end
          end
        elsif outcome_part.include?('run') || outcome_part.include?('runs')
          runs = outcome_part.split(' ').first.to_i
        elsif outcome_part.include?('SIX')
          runs = 6
        elsif outcome_part.include?('FOUR')
          runs = 4
        elsif outcome_part.include?('wide') || outcome_part.include?('no ball')
          extras = 1
        end
        
        # Create delivery object
        delivery = {
          bowler: bowler,
          batsman: batsman,
          runs: runs,
          extras: extras,
          wicket: wicket,
          wicket_type: wicket_type,
          wicket_details: wicket_details,
          description: line
        }
        
        current_over[:deliveries] << delivery
        
        # Update bowler's stats
        bowler_stats = current_match[:current_innings][:bowlers][bowler][:stats] || {}
        bowler_stats[:runs_conceded] ||= 0
        bowler_stats[:runs_conceded] += runs + extras
        bowler_stats[:balls_bowled] ||= 0
        bowler_stats[:balls_bowled] += 1 unless outcome_part.include?('wide') || outcome_part.include?('no ball')
        bowler_stats[:wickets] ||= 0
        bowler_stats[:wickets] += 1 if wicket
        
        # Update batsman's runs if not a wicket
        unless wicket
          batsman_stats = current_match[:current_innings][:batsmen][batsman] ||= {}
          batsman_stats[:runs] ||= 0
          batsman_stats[:runs] += runs
          batsman_stats[:balls] ||= 0
          batsman_stats[:balls] += 1 unless outcome_part.include?('wide')
          batsman_stats[:fours] ||= 0
          batsman_stats[:fours] += 1 if runs == 4
          batsman_stats[:sixes] ||= 0
          batsman_stats[:sixes] += 1 if runs == 6
        end
      end
    end
    # Convert to CSV format
    csv_data = CSV.generate(headers: true) do |csv|
      csv << [
        'match_id', 'over', 'ball', 'bowler', 'batsman', 'runs', 'extras', 'wicket', 
        'wicket_type', 'wicket_details', 'batsman_runs', 'batsman_balls', 'batsman_4s', 
        'batsman_6s', 'batsman_sr', 'bowler_wickets', 'bowler_econ', 'bowler_best',
        'batsman_total_matches', 'batsman_total_runs', 'batsman_avg', 'batsman_total_6s',
        'bowler_total_matches', 'bowler_total_wickets', 'bowler_total_econ', 'bowler_total_best'
      ]
      
      matches.each do |match|
        match[:current_innings][:overs].each do |over|
          over[:deliveries].each do |delivery|
            batsman_stats = match[:current_innings][:batsmen][delivery[:batsman]] || {}
            bowler_stats = match[:current_innings][:bowlers][delivery[:bowler]] || {}
            
            csv << [
              match[:id],
              over[:number],
              over[:ball],
              delivery[:bowler],
              delivery[:batsman],
              delivery[:runs],
              delivery[:extras],
              delivery[:wicket] ? 1 : 0,
              delivery[:wicket_type],
              delivery[:wicket_details],
              batsman_stats[:runs],
              batsman_stats[:balls],
              batsman_stats[:fours],
              batsman_stats[:sixes],
              batsman_stats[:strike_rate],
              bowler_stats[:wickets],
              bowler_stats[:economy],
              bowler_stats[:best],
              batsman_stats[:mat],
              batsman_stats[:runs],
              batsman_stats[:avg],
              batsman_stats[:hr],
              bowler_stats[:mat],
              bowler_stats[:wickets],
              bowler_stats[:eco],
              bowler_stats[:best]
            ]
          end
        end
      end
    end
    
    { structured_data: matches, csv_data: csv_data }
  end

# Example usage:
# raw_data = File.read('cricket_commentary.txt')
# result = extract_cricket_stats(raw_data)
# puts result[:csv_data]  # This will output the CSV
# File.write('cricket_stats.csv', result[:csv_data])

  def fetch_data_by_prefix(prefix)
    batting_file = Rails.root.join('lib', 'spl_data', "#{prefix}_batting.csv")
    bowling_file = Rails.root.join('lib', 'spl_data', "#{prefix}_bowling.csv")
    batting_data = process_batting_fields(batting_file) if batting_file
    bowling_data = process_bowling_fields(bowling_file) if bowling_file

    {
      batting: batting_data || [],
      bowling: bowling_data || []
    }
  end

  def fetch_combined_batting_data(*prefixes)
    combined_data = {}

    prefixes.each do |prefix|
      batting_file = Rails.root.join('lib', 'spl_data', "#{prefix}_batting.csv")
      next unless File.exist?(batting_file)

      season_data = process_batting_fields(batting_file)
      season_data.each do |player_data|
        player_name = player_data[:player_name]

        # Initialize player data if not already present
        combined_data[player_name] ||= {
          player_name:,
          matches_played: 0,
          innings: 0,
          runs: 0,
          balls: 0,
          not_out: 0,
          highest_score: 0,
          avg: '-',
          sr: 0,
          fours: 0,
          sixes: 0,
          fifties: 0,
          hundreds: 0
        }
        # Combine fields
        combined_data[player_name][:matches_played] += player_data[:matches_played].to_i
        combined_data[player_name][:innings] += player_data[:innings].to_i
        combined_data[player_name][:runs] += player_data[:runs].to_i
        combined_data[player_name][:balls] += player_data[:balls].to_i
        combined_data[player_name][:not_out] += player_data[:not_out].to_i
        combined_data[player_name][:fours] += player_data[:fours].to_i
        combined_data[player_name][:sixes] += player_data[:sixes].to_i
        combined_data[player_name][:fifties] += player_data[:fifties].to_i
        combined_data[player_name][:hundreds] += player_data[:hundreds].to_i

        # Update highest score
        current_highest = player_data[:highest_score].to_i
        combined_data[player_name][:highest_score] = [combined_data[player_name][:highest_score], current_highest].max

        # Update strike rate dynamically if balls > 0
        total_runs = combined_data[player_name][:runs]
        total_balls = combined_data[player_name][:balls]
        combined_data[player_name][:sr] = total_balls.positive? ? ((total_runs.to_f / total_balls) * 100).round(2) : 0

        # Update average dynamically if (innings - not_out) > 0
        total_innings = combined_data[player_name][:innings]
        total_not_out = combined_data[player_name][:not_out]
        dismissals = total_innings - total_not_out
        # dismissals = total_innings

        combined_data[player_name][:avg] = dismissals.positive? ? (total_runs.to_f / dismissals).round(2) : '-'
      end
    end

    combined_data.values.sort_by { |player| [-player[:runs], -player[:sr]] } # Sort players by total runs
  end

  def fetch_combined_bowling_data(*prefixes)
    combined_data = {}
    prefixes.each do |prefix|
      bowling_file = Rails.root.join('lib', 'spl_data', "#{prefix}_bowling.csv")
      next unless File.exist?(bowling_file)

      season_data = process_bowling_fields(bowling_file)
      season_data.each do |player_data|
        player_name = player_data[:player]

        # Initialize player data if not already present
        combined_data[player_name] ||= {
          player_name:,
          matches_played: 0,
          innings: 0,
          overs: 0,
          runs_given: 0,
          wickets: 0,
          maidens: 0,
          econ: 0
        }

        # Combine fields
        combined_data[player_name][:matches_played] += player_data[:matches_played].to_i
        combined_data[player_name][:innings] += player_data[:innings].to_i
        combined_data[player_name][:overs] += player_data[:overs].to_i
        # combined_data[player_name][:balls] += player_data[:balls].to_i
        combined_data[player_name][:runs_given] += player_data[:runs_given].to_i
        combined_data[player_name][:wickets] += player_data[:wickets].to_i
        combined_data[player_name][:maidens] += player_data[:maidens].to_i
        combined_data[player_name][:econ] += player_data[:econ].to_f

        # update economy rate, count avg eco for all season option only
        if prefixes.count > 1
          combined_data[player_name][:econ] =
            (combined_data[player_name][:runs_given].to_f / combined_data[player_name][:overs]).round(2)
        end
      end
    end
    combined_data&.values&.sort_by { |player| [-player[:wickets], player[:econ]] }
  end

  # Process the batting fields in all CSV files
  def process_batting_fields_from_all_csv
    data = nil
    @csv_files.each do |csv_file|
      data = process_batting_fields(csv_file)
    end
    data
  end

  # Process the bowling fields in all CSV files
  def process_bowling_fields_from_all_csv
    data = nil
    @csv_files.each do |csv_file|
      data = process_bowling_fields(csv_file)
    end
    data
  end

  private

  # Method to process batting fields from a single CSV file
  def process_batting_fields(csv_file)
    data = []
    CSV.foreach(csv_file, headers: true) do |row|
      data << generate_output_hash_for_batting(row)
    end
    data
  end

  def generate_output_hash_for_batting(row)
    {
      player_name: row['PlayerName'],
      matches_played: row['Mat'],
      innings: row['Inns'],
      runs: row['Runs'],
      balls: row['Balls'],
      not_out: row['N/O'],
      highest_score: row['Highest'],
      avg: row['Avg'],
      sr: row['SR'],
      fours: row['4s'],
      sixes: row['6s'],
      fifties: row['50s'],
      hundreds: row['100s']
    }
  end

  # Method to process bowling fields from a single CSV file
  def process_bowling_fields(csv_file)
    data = []
    CSV.foreach(csv_file, headers: true) do |row|
      data << generate_output_hash_for_bowling(row)
    end
    data
  end

  def generate_output_hash_for_bowling(row)
    {
      player: row['Player'],
      matches_played: row['Match'],
      innings: row['Ing'],
      overs: row['Overs'],
      runs_given: row['Run'],
      wickets: row['Wickets'],
      maidens: row['Maidens'],
      econ: row['Econ']
    }
  end
end
