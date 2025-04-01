# frozen_string_literal: true

require 'csv'

class DataAnalyzer
  attr_accessor :csv_files

  # Initialize the class with an array of CSV files
  # def initialize(*csv_files)
  #   @csv_files = csv_files
  # end

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
        combined_data[player_name][:econ] += player_data[:econ].to_i

        # update economy rate
        combined_data[player_name][:econ] =
          (combined_data[player_name][:runs_given].to_f / combined_data[player_name][:overs]).round(2)
      end
    end

    combined_data.values.sort_by { |player| [-player[:wickets], player[:econ]] }
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
