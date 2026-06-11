# frozen_string_literal: true

class PlayerStatistic < ApplicationRecord
  belongs_to :player

  validates :cricbuzz_player_id, uniqueness: true, allow_nil: true

  # Formats
  FORMATS = %w[test odi t20 ipl].freeze

  # Get batting stats for a specific format
  def batting_stats(format)
    return {} unless FORMATS.include?(format)

    {
      matches: send("#{format}_matches"),
      innings: send("#{format}_innings"),
      runs: send("#{format}_runs"),
      balls: send("#{format}_balls"),
      highest: send("#{format}_highest"),
      average: send("#{format}_average"),
      strike_rate: send("#{format}_strike_rate"),
      not_out: send("#{format}_not_out"),
      fours: send("#{format}_fours"),
      sixes: send("#{format}_sixes"),
      ducks: send("#{format}_ducks"),
      fifties: send("#{format}_fifties"),
      hundreds: send("#{format}_hundreds"),
      double_hundreds: send("#{format}_double_hundreds")
    }
  end

  # Get bowling stats for a specific format
  def bowling_stats(format)
    return {} unless FORMATS.include?(format)

    {
      innings: send("#{format}_bowling_innings"),
      balls: send("#{format}_bowling_balls"),
      runs: send("#{format}_bowling_runs"),
      maidens: send("#{format}_bowling_maidens"),
      wickets: send("#{format}_bowling_wickets"),
      average: send("#{format}_bowling_average"),
      economy: send("#{format}_bowling_economy"),
      strike_rate: send("#{format}_bowling_strike_rate"),
      best_bowling_innings: send("#{format}_best_bowling_innings"),
      best_bowling_match: send("#{format}_best_bowling_match"),
      four_wickets: send("#{format}_four_wickets"),
      five_wickets: send("#{format}_five_wickets"),
      ten_wickets: send("#{format}_ten_wickets")
    }
  end

  # Get all stats summary
  def stats_summary
    FORMATS.map do |format|
      {
        format: format.upcase,
        batting: batting_stats(format),
        bowling: bowling_stats(format)
      }
    end
  end

  # Check if stats are stale (older than 24 hours)
  def stale?
    last_synced_at.nil? || last_synced_at < 24.hours.ago
  end
end
