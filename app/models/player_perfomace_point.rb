# frozen_string_literal: true

class PlayerPerfomacePoint < ApplicationRecord
  belongs_to :player
  belongs_to :team
  include BonusPoints

#   scope :orange_cap_players, ->(auction_id) {
#   total_runs_query = PlayerPerfomacePoint
#                       .joins(team: :auction) # Ensures the team is linked to the auction
#                       .where(teams: { auction_id: auction_id }) # Filters by auction_id
#                       .group('player_perfomace_points.player_id')
#                       .select('player_perfomace_points.player_id, SUM(player_perfomace_points.runs) as total_runs')

#   PlayerPerfomacePoint
#     .joins("INNER JOIN (#{total_runs_query.to_sql}) AS tr ON tr.player_id = player_perfomace_points.player_id")
#     .order('tr.total_runs DESC')
#     .limit(10)
# }

# scope :purple_cap_players, ->(auction_id) {
#   total_wickets_query = PlayerPerfomacePoint
#                          .joins(team: :auction) # Ensures the team is linked to the auction
#                          .where(teams: { auction_id: auction_id }) # Filters by auction_id
#                          .group('player_perfomace_points.player_id')
#                          .select('player_perfomace_points.player_id, SUM(player_perfomace_points.wickets) as total_wickets')

#   PlayerPerfomacePoint
#     .joins("INNER JOIN (#{total_wickets_query.to_sql}) AS tw ON tw.player_id = player_perfomace_points.player_id")
#     .order('tw.total_wickets DESC')
#     .limit(10)
# }



  POINTS_EVALUATION = {
    in_playing11: 4,

    #batting points
    runs: 1,
    fours: 2,
    sixes: 4,
    fifties: 4,
    hundreds: 8,
    bonus_30: 4,
    bonus_50: 8,
    bonus_100: 10,
    duck: -5,
    # strike_rate: calculate_strike_rate_points

    #bowling points
    wickets: 25,
    maidens: 10,
    lbw_bonus: 8,
    bowled_bonus: 8,
    bonus_3w: 5,
    bonus_4w: 8,
    bonus_5w: 10,
    
    #fielding points
    catches: 8,
    run_outs: 10,
    stumping: 12,

    #MOM points
    bonus_mom: 0
  }.freeze

  class << self
    def create_record(**columns)
      create(columns)
    end

    def calculate_bowled_and_lbw_points(match_name)
      out_desc = WicketDesc.where(match_name:).pluck(:desc).flatten
      # out_desc = out_desc_hash.values.compact_blank
      dismissals = { lbw: Hash.new(0), bowled: Hash.new(0) }
      out_desc.each do |desc|
        if desc.include?("lbw")
          # Extract bowler's name for lbw
          bowler = desc.match(/lbw b\s+(.*)$/)&.captures&.first
          dismissals[:lbw][bowler] += 1 if bowler
        elsif desc.start_with?("b ") && !desc.match?(/(c |st |run out)/)
          bowler = desc.match(/b\s+(.*)$/)&.captures&.first
          dismissals[:bowled][bowler] += 1 if bowler
        end
      end
      dismissals
    end

    def orange_cap_players(auction_id)
      auction = Auction.find(auction_id)
      pool_team_ids = auction.teams.pluck(:id)
      
      # Fetch the top 10 players with the highest total runs, and if runs are equal, order by strike_rate
      top_players = PlayerPerfomacePoint
        .where(team_id: pool_team_ids)
        .group(:player_id)
        .select('player_id, SUM(runs) as total_runs, AVG(strike_rate) as average_strike_rate')
        .order(Arel.sql('SUM(runs) DESC, AVG(strike_rate) DESC')) # Order by runs and then by strike_rate
      
      # Fetch player details for the top 10 players
      player_ids = top_players.limit(10).pluck(:player_id) # Limit after ordering
      players = Player.where(id: player_ids).index_by(&:id)
      
      # Combine player details with their total runs and average strike rate
      top_players.limit(10).map do |pp|
        player = players[pp.player_id]
        { player: player, total_runs: pp.total_runs, average_strike_rate: pp.average_strike_rate }
      end
    end

    def purple_cap_players(auction_id)
      auction = Auction.find(auction_id)
      pool_team_ids = auction.teams.pluck(:id)
      
      # Fetch the top 10 players with the highest total wickets, and if wickets are equal, order by economy rate (eco)
      top_players = PlayerPerfomacePoint
        .where(team_id: pool_team_ids)
        .group(:player_id)
        .select('player_id, SUM(wickets) as total_wickets, AVG(eco) as average_eco')
        .order(Arel.sql('SUM(wickets) DESC, AVG(eco) ASC')) # Order by wickets and then by economy rate (ascending)
      
      # Fetch player details for the top 10 players
      player_ids = top_players.limit(10).pluck(:player_id) # Limit after ordering
      players = Player.where(id: player_ids).index_by(&:id)
      
      # Combine player details with their total wickets and average economy rate
      top_players.limit(10).map do |pp|
        player = players[pp.player_id]
        { player: player, total_wickets: pp.total_wickets, average_eco: pp.average_eco }
      end
    end

    def top_fantasy_players(auction_id)
      auction = Auction.find(auction_id)
      pool_team_ids = auction.teams.pluck(:id)
      top_player = PlayersTeam.where(team_id: pool_team_ids).order(points: :desc).limit(10).pluck(:player_id)
    end
  end

  # def assign_bowled_and_lbw_points
  #   points_data = self.class.calculate_bowled_and_lbw_points(match)
  #   points_data.each do |k,v|
  #     next if v.blank?

  #         #CHANGE FIRSt TO LAST AFTER UPDATINFG FIRST WEEK POINTS
  #     v.keys.each do |name|
  #       if team.weekly_user_teams.count > 1
  #         playing11_ids = team.weekly_user_teams.where("week_end_date >= ?", Date.current)&.first&.playing11 || team.weekly_user_teams.last.playing11
  #       else
  #         playing11_ids = team.weekly_user_teams.last.playing11
  #       end
  #       c_player = team.players
  #                      .where(id: playing11_ids)
  #                      .where("name ILIKE ?", "#{name}").first || team.players
  #                                                                          .where(id: playing11_ids)
  #                                                                          .where("name ILIKE ?", "%#{name}%").first
  #       next if c_player.blank? || c_player != player
        
  #       pp_record = c_player.player_perfomace_points.where(team:, match:)&.first
  #       next if pp_record.blank?

  #       k == :lbw ? lbw_bonus = (points_data[k][name] || 0) : bowled_bonus = (points_data[k][name] || 0)
  #       lbw_bonus_points = POINTS_EVALUATION[:lbw_bonus] * (lbw_bonus || 0)
  #       bowled_bonus_points = POINTS_EVALUATION[:bowled_bonus] * (bowled_bonus || 0)
  #       player_updated_total_points = c_player.players_teams.where(team:)&.first&.points + lbw_bonus_points + bowled_bonus_points
  #       match_record = Match.where(match_name: match, player: c_player, team:)&.first
  #       match_record_total_points = (match_record&.points || 0) + lbw_bonus_points + bowled_bonus_points
  #       match_record&.update(points: match_record_total_points)
  #       c_player.players_teams.where(team:)&.first&.update_columns(points: player_updated_total_points)
  #       pp_record.update_columns(lbw_bonus: lbw_bonus_points) if lbw_bonus_points > 0
  #       pp_record.update_columns(bowled_bonus: bowled_bonus_points) if bowled_bonus_points > 0
  #     end
  #   end
  # end

  def match_points
    data = {
              in_playing11: in_playing11,
              batting_points: calculate_batting_points,
              bowling_points: calculate_bowling_points,
              fielding_points: calculate_fielding_points,
              calculate_mom_bonus: calculate_mom_bonus
            }
    data.values.sum
    # data
  end


  def calculate_field_points(field)
    evaulted_points = POINTS_EVALUATION[field.to_sym] * send(field)
  end

  def display_batting_bonus_points
    batting_bonus_columns = %w[bonus_30 bonus_50 bonus_100]
    columns = batting_bonus_columns.reject { |field| send(field).zero?  }
    return {field_name: '-', value: '-'} if columns.blank?

    { field_name: columns.first.gsub('_','-').capitalize, value: send(columns.first) }
  end

  private

  def calculate_mom_bonus
    is_mom? ? POINTS_EVALUATION[:bonus_mom] : 0
  end

  def calculate_batting_points
    batting_points.values.sum + batting_bonus_points.values.sum
  end

  def calculate_bowling_points
    # bowling_points.values.sum + bowling_bonus_points.values.sum

    # we calculate => bowling_bonus_points in after_commit
    bowling_points.values.sum
  end

  def calculate_fielding_points
    fielding_points.values.sum # we calculate => fielding_bonus_points in after_commit
  end

  def batting_points
    {
      runs: POINTS_EVALUATION[:runs] * runs,
      fours: POINTS_EVALUATION[:fours] * fours,
      sixes: POINTS_EVALUATION[:sixes] * sixes
      # strike_rate: POINTS_EVALUATION[:strike_rate] * strike_rate
    }
  end

  def batting_bonus_points
    {
      duck: duck? ? (POINTS_EVALUATION[:duck]) : 0
    }
  end

  def bowling_points
    {
      wickets: POINTS_EVALUATION[:wickets] * wickets,
      maidens: POINTS_EVALUATION[:maidens] * maidens
    }
  end

  def fielding_points
    {
      catches: POINTS_EVALUATION[:catches] * catches ,
      run_outs: POINTS_EVALUATION[:run_outs] * run_outs,
      stumping: POINTS_EVALUATION[:stumping] * stumping
    }
  end
end
