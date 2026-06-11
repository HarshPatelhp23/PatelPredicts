# frozen_string_literal: true

# app/services/cricbuzz_service.rb
require 'httparty'

class CricbuzzService
  include HTTParty
  base_uri 'https://cricbuzz-cricket.p.rapidapi.com'

  STAT_TYPE_BATTING = 'batting'
  STAT_TYPE_BOWLING = 'bowling'

  def initialize
    @headers = {
      'x-rapidapi-key' => Rails.application.credentials.dig(:rapid_api, :key),
      'x-rapidapi-host' => 'cricbuzz-cricket.p.rapidapi.com'
    }
  end

  # Fetch batting statistics for a player
  def fetch_batting_stats(player_id)
    fetch_stats(player_id, STAT_TYPE_BATTING)
  end

  # Fetch bowling statistics for a player
  def fetch_bowling_stats(player_id)
    fetch_stats(player_id, STAT_TYPE_BOWLING)
  end

  # Fetch both batting and bowling stats
  def fetch_all_stats(player_id)
    {
      batting: fetch_batting_stats(player_id),
      bowling: fetch_bowling_stats(player_id)
    }
  end

  # Update player statistics in database
  def update_player_stats(player, cricbuzz_player_id)
    stats_data = fetch_all_stats(cricbuzz_player_id)
    return { success: false, error: 'Failed to fetch stats' } if stats_data[:batting].nil? && stats_data[:bowling].nil?

    player_stat = player.player_statistic || player.build_player_statistic
    player_stat.cricbuzz_player_id = cricbuzz_player_id

    # Parse and update batting stats
    if stats_data[:batting].present?
      parse_batting_stats(stats_data[:batting], player_stat)
    end

    # Parse and update bowling stats
    if stats_data[:bowling].present?
      parse_bowling_stats(stats_data[:bowling], player_stat)
    end

    player_stat.last_synced_at = Time.current

    if player_stat.save
      { success: true, player_statistic: player_stat }
    else
      { success: false, errors: player_stat.errors.full_messages }
    end
  rescue StandardError => e
    Rails.logger.error "Error updating stats for player #{player.id}: #{e.message}"
    { success: false, error: e.message }
  end

  private

  def fetch_stats(player_id, stat_type)
    response = self.class.get(
      "/stats/v1/player/#{player_id}/#{stat_type}",
      headers: @headers
    )
    return nil unless response.success?

    JSON.parse(response.body)
  rescue StandardError => e
    Rails.logger.error "Error fetching #{stat_type} stats for player #{player_id}: #{e.message}"
    nil
  end

  def parse_batting_stats(data, player_stat)
    return unless data['headers'] && data['values']

    headers = data['headers']
    values_array = data['values']

    # Map format names to column prefixes
    format_map = {
      'Test' => 'test',
      'ODI' => 'odi',
      'T20' => 't20',
      'IPL' => 'ipl'
    }

    # Map stat names to database columns
    stat_map = {
      'Matches' => 'matches',
      'Innings' => 'innings',
      'Runs' => 'runs',
      'Balls' => 'balls',
      'Highest' => 'highest',
      'Average' => 'average',
      'SR' => 'strike_rate',
      'Not Out' => 'not_out',
      'Fours' => 'fours',
      'Sixes' => 'sixes',
      'Ducks' => 'ducks',
      '50s' => 'fifties',
      '100s' => 'hundreds',
      '200s' => 'double_hundreds'
    }

    values_array.each do |row|
      row_values = row['values']
      stat_name = row_values[0]
      
      next unless stat_map[stat_name]

      headers[1..].each_with_index do |format, index|
        next unless format_map[format]

        column_name = "#{format_map[format]}_#{stat_map[stat_name]}"
        value = row_values[index + 1]

        next if value.nil? || value == '-' || value == '-/-'

        # Convert value to appropriate type
        if %w[highest].include?(stat_map[stat_name])
          player_stat.send("#{column_name}=", value.to_s)
        elsif %w[average strike_rate].include?(stat_map[stat_name])
          # Use BigDecimal for precise decimal handling
          player_stat.send("#{column_name}=", BigDecimal(value.to_s).round(2))
        else
          player_stat.send("#{column_name}=", value.to_i)
        end
      end
    end
  end

  def parse_bowling_stats(data, player_stat)
    return unless data['headers'] && data['values']

    headers = data['headers']
    values_array = data['values']

    format_map = {
      'Test' => 'test',
      'ODI' => 'odi',
      'T20' => 't20',
      'IPL' => 'ipl'
    }

    stat_map = {
      'Innings' => 'bowling_innings',
      'Balls' => 'bowling_balls',
      'Runs' => 'bowling_runs',
      'Maidens' => 'bowling_maidens',
      'Wickets' => 'bowling_wickets',
      'Avg' => 'bowling_average',
      'Eco' => 'bowling_economy',
      'SR' => 'bowling_strike_rate',
      'BBI' => 'best_bowling_innings',
      'BBM' => 'best_bowling_match',
      '4w' => 'four_wickets',
      '5w' => 'five_wickets',
      '10w' => 'ten_wickets'
    }

    values_array.each do |row|
      row_values = row['values']
      stat_name = row_values[0]
      
      next unless stat_map[stat_name]

      headers[1..].each_with_index do |format, index|
        next unless format_map[format]

        column_name = "#{format_map[format]}_#{stat_map[stat_name]}"
        value = row_values[index + 1]

        next if value.nil? || value == '-' || value == '-/-' || value == '0'

        # Convert value to appropriate type
        if %w[best_bowling_innings best_bowling_match].include?(stat_map[stat_name])
          player_stat.send("#{column_name}=", value.to_s) unless value == '-/-'
        elsif %w[bowling_average bowling_economy bowling_strike_rate].include?(stat_map[stat_name])
          # Use BigDecimal for precise decimal handling
          decimal_value = BigDecimal(value.to_s).round(2)
          player_stat.send("#{column_name}=", decimal_value) unless decimal_value.zero?
        else
          player_stat.send("#{column_name}=", value.to_i)
        end
      end
    end
  end
end
