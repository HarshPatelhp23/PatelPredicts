# app/controllers/players_controller.rb

class PlayersController < ApplicationController
  # ... your existing actions ...

  # GET /players/:id/statistics
  def statistics
    @player = Player.find(params[:id])
    
    # Check if stats exist and are not stale
    if @player.stats_need_update?
      # You might want to do this asynchronously in production
      # For now, we'll just return what we have or empty stats
      stats = build_empty_stats
    else
      stats = build_player_stats(@player.player_statistic)
    end

    render json: stats
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Player not found' }, status: :not_found
  end

  # POST /players/:id/sync_statistics
  # This endpoint triggers a sync with Cricbuzz API
  def sync_statistics
    @player = Player.find(params[:id])
    cricbuzz_id = params[:cricbuzz_id]

    unless cricbuzz_id.present?
      return render json: { error: 'Cricbuzz player ID is required' }, status: :unprocessable_entity
    end

    service = CricbuzzService.new
    result = service.update_player_stats(@player, cricbuzz_id)

    if result[:success]
      stats = build_player_stats(result[:player_statistic])
      render json: { success: true, statistics: stats }
    else
      render json: { 
        success: false, 
        error: result[:error] || result[:errors]&.join(', ') 
      }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Player not found' }, status: :not_found
  end

  private

  def build_player_stats(player_stat)
    return build_empty_stats if player_stat.nil?

    {
      test: format_stats(player_stat, 'test'),
      odi: format_stats(player_stat, 'odi'),
      t20: format_stats(player_stat, 't20'),
      ipl: format_stats(player_stat, 'ipl'),
      last_synced: player_stat.last_synced_at
    }
  end

  def format_stats(player_stat, format)
    {
      batting: {
        matches: player_stat.send("#{format}_matches"),
        innings: player_stat.send("#{format}_innings"),
        runs: player_stat.send("#{format}_runs"),
        balls: player_stat.send("#{format}_balls"),
        highest: player_stat.send("#{format}_highest"),
        average: player_stat.send("#{format}_average")&.to_f&.round(2),
        strike_rate: player_stat.send("#{format}_strike_rate")&.to_f&.round(2),
        not_out: player_stat.send("#{format}_not_out"),
        fours: player_stat.send("#{format}_fours"),
        sixes: player_stat.send("#{format}_sixes"),
        ducks: player_stat.send("#{format}_ducks"),
        fifties: player_stat.send("#{format}_fifties"),
        hundreds: player_stat.send("#{format}_hundreds"),
        double_hundreds: player_stat.send("#{format}_double_hundreds")
      },
      bowling: {
        innings: player_stat.send("#{format}_bowling_innings"),
        balls: player_stat.send("#{format}_bowling_balls"),
        runs: player_stat.send("#{format}_bowling_runs"),
        maidens: player_stat.send("#{format}_bowling_maidens"),
        wickets: player_stat.send("#{format}_bowling_wickets"),
        average: player_stat.send("#{format}_bowling_average")&.to_f&.round(2),
        economy: player_stat.send("#{format}_bowling_economy")&.to_f&.round(2),
        strike_rate: player_stat.send("#{format}_bowling_strike_rate")&.to_f&.round(2),
        best_bowling_innings: player_stat.send("#{format}_best_bowling_innings"),
        best_bowling_match: player_stat.send("#{format}_best_bowling_match"),
        four_wickets: player_stat.send("#{format}_four_wickets"),
        five_wickets: player_stat.send("#{format}_five_wickets"),
        ten_wickets: player_stat.send("#{format}_ten_wickets")
      }
    }
  end

  def build_empty_stats
    {
      test: empty_format_stats,
      odi: empty_format_stats,
      t20: empty_format_stats,
      ipl: empty_format_stats,
      last_synced: nil
    }
  end

  def empty_format_stats
    {
      batting: {
        matches: 0, innings: 0, runs: 0, balls: 0, highest: nil,
        average: 0, strike_rate: 0, not_out: 0, fours: 0, sixes: 0,
        ducks: 0, fifties: 0, hundreds: 0, double_hundreds: 0
      },
      bowling: {
        innings: 0, balls: 0, runs: 0, maidens: 0, wickets: 0,
        average: 0, economy: 0, strike_rate: 0, best_bowling_innings: nil,
        best_bowling_match: nil, four_wickets: 0, five_wickets: 0, ten_wickets: 0
      }
    }
  end
end
