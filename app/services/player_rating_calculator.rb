# class PlayerRatingCalculator
#   def self.calculate(player_data)
#     total_runs = 0
#     total_matches = 0
#     total_sr = 0
#     total_wickets = 0
#     total_econ = 0
#     seasons_with_data = 0
    
#     %w[4 5 6 7 8].each do |spl|
#       if player_data["spl#{spl}_matches".to_sym].to_i > 0
#         total_runs += player_data["spl#{spl}_run".to_sym].to_i
#         total_matches += player_data["spl#{spl}_matches".to_sym].to_i
#         total_sr += player_data["spl#{spl}_sr".to_sym].to_f
#         total_wickets += player_data["spl#{spl}_wickets".to_sym].to_i
#         econ = player_data["spl#{spl}_econ".to_sym].to_f
#         total_econ += econ > 0 ? econ : 0
#         seasons_with_data += 1
#       end
#     end
    
#     return 3.0 if seasons_with_data == 0
    
#     seasons_with_data = [seasons_with_data, 1].max
    
#     avg_runs = total_runs.to_f / seasons_with_data
#     avg_sr = total_sr.to_f / seasons_with_data
#     avg_wickets = total_wickets.to_f / seasons_with_data
#     avg_econ = total_econ.to_f / seasons_with_data
    
#     # Rating calculation (same as your existing logic)
#     base_points = 2.0
#     runs_weight = [avg_runs / 25.0 * 4.0, 4.0].min
    
#     sr_points = 0
#     if avg_sr > 0
#       if avg_sr >= 170
#         sr_points = 1.75
#       elsif avg_sr >= 140
#         sr_points = 1.25
#       elsif avg_sr >= 120
#         sr_points = 0.75
#       elsif avg_sr >= 100
#         sr_points = 0.25
#       end
#     end
    
#     wicket_points = [avg_wickets * 0.6, 2.0].min
    
#     econ_points = 0
#     if avg_econ > 0
#       if avg_econ <= 8
#         econ_points = 1.75
#       elsif avg_econ <= 10
#         econ_points = 1.25
#       elsif avg_econ <= 12
#         econ_points = 0.75
#       elsif avg_econ <= 14
#         econ_points = 0.25
#       end
#     end
#     rating = [base_points + runs_weight + sr_points + wicket_points + econ_points, 10.0].min.round(1)
#     [rating, 3.0].max
#   end
# end


class PlayerRatingCalculator
  def self.calculate(player_data)
    total_runs = 0
    total_matches = 0
    total_sr = 0
    total_wickets = 0
    total_econ = 0
    seasons_with_data = 0
    
    %w[4 5 6 7 8 9].each do |spl|
      matches = player_data["spl#{spl}_matches".to_sym].to_i
      if matches > 0
        total_runs += player_data["spl#{spl}_run".to_sym].to_i
        total_matches += matches
        total_sr += player_data["spl#{spl}_sr".to_sym].to_f
        total_wickets += player_data["spl#{spl}_wickets".to_sym].to_i
        econ = player_data["spl#{spl}_econ".to_sym].to_f
        total_econ += econ > 0 ? econ : 0
        seasons_with_data += 1
      end
    end
    
    return 3.0 if seasons_with_data == 0
    
    seasons_with_data = [seasons_with_data, 1].max
    
    # Calculate averages
    avg_runs = total_runs.to_f / seasons_with_data
    avg_sr = total_sr.to_f / seasons_with_data
    avg_wickets = total_wickets.to_f / seasons_with_data
    avg_econ = total_econ.to_f / seasons_with_data
    
    # Calculate match volume factor (new addition)
    match_volume_factor = calculate_match_volume_factor(total_matches)
    
    # Base rating calculation
    base_points = 2.0
    runs_weight = [avg_runs / 25.0 * 4.0, 4.0].min
    
    sr_points = 0
    if avg_sr > 0
      if avg_sr >= 170
        sr_points = 1.75
      elsif avg_sr >= 140
        sr_points = 1.25
      elsif avg_sr >= 120
        sr_points = 0.75
      elsif avg_sr >= 100
        sr_points = 0.25
      end
    end
    
    wicket_points = [avg_wickets * 0.6, 2.0].min
    
    econ_points = 0
    if avg_econ > 0
      if avg_econ <= 8
        econ_points = 1.75
      elsif avg_econ <= 10
        econ_points = 1.25
      elsif avg_econ <= 12
        econ_points = 0.75
      elsif avg_econ <= 14
        econ_points = 0.25
      end
    end
    
    # Apply match volume factor to the raw rating
    raw_rating = base_points + runs_weight + sr_points + wicket_points + econ_points
    adjusted_rating = raw_rating * match_volume_factor
    
    final_rating = [adjusted_rating, 10.0].min.round(1)
    [final_rating, 3.0].max
  end




  # def self.calculate_batting_rating(player_data)
  #   total_runs = 0
  #   total_balls = 0
  #   total_matches = 0
  #   total_highest = 0
  #   total_fours = 0
  #   total_sixes = 0
  #   total_fifties = 0
  #   total_hundreds = 0
  #   seasons_with_batting_data = 0
    
  #   %w[4 5 6 7 8].each do |spl|
  #     matches = player_data["spl#{spl}_matches".to_sym].to_i
  #     runs = player_data["spl#{spl}_run".to_sym].to_i
      
  #     if matches > 0 && runs > 0
  #       total_runs += runs
  #       total_balls += player_data["spl#{spl}_balls".to_sym].to_i
  #       total_matches += matches
  #       total_highest += player_data["spl#{spl}_highest".to_sym].to_i
  #       total_fours += player_data["spl#{spl}_4s".to_sym].to_i
  #       total_sixes += player_data["spl#{spl}_6s".to_sym].to_i
  #       total_fifties += player_data["spl#{spl}_50s".to_sym].to_i
  #       total_hundreds += player_data["spl#{spl}_100s".to_sym].to_i
  #       seasons_with_batting_data += 1
  #     end
  #   end
    
  #   return 0 if seasons_with_batting_data == 0 || total_balls == 0
    
  #   # Calculate key metrics
  #   batting_avg = total_runs.to_f / [seasons_with_batting_data, 1].max
  #   strike_rate = (total_runs.to_f / total_balls) * 100
  #   avg_highest = total_highest.to_f / seasons_with_batting_data
  #   boundary_percentage = ((total_fours + total_sixes).to_f / total_balls) * 100
  #   milestone_frequency = ((total_fifties + total_hundreds).to_f / total_matches) * 100
    
  #   # Calculate match volume factor
  #   match_volume_factor = calculate_match_volume_factor(total_matches)
    
  #   # Batting rating calculation (out of 100)
  #   rating = 0
    
  #   # Runs contribution (max 40 points)
  #   runs_points = if batting_avg >= 150
  #                  40
  #                elsif batting_avg >= 100
  #                  35
  #                elsif batting_avg >= 75
  #                  30
  #                elsif batting_avg >= 50
  #                  25
  #                elsif batting_avg >= 30
  #                  20
  #                elsif batting_avg >= 20
  #                  15
  #                elsif batting_avg >= 10
  #                  10
  #                else
  #                  5
  #                end
    
  #   # Strike rate contribution (max 25 points)
  #   sr_points = if strike_rate >= 200
  #                 25
  #               elsif strike_rate >= 180
  #                 22
  #               elsif strike_rate >= 160
  #                 19
  #               elsif strike_rate >= 140
  #                 16
  #               elsif strike_rate >= 120
  #                 13
  #               elsif strike_rate >= 100
  #                 10
  #               else
  #                 5
  #               end
    
  #   # Boundary hitting (max 15 points)
  #   boundary_points = if boundary_percentage >= 40
  #                      15
  #                    elsif boundary_percentage >= 30
  #                      12
  #                    elsif boundary_percentage >= 20
  #                      9
  #                    elsif boundary_percentage >= 10
  #                      6
  #                    else
  #                      3
  #                    end
    
  #   # Milestone frequency (max 10 points)
  #   milestone_points = if milestone_frequency >= 50
  #                       10
  #                     elsif milestone_frequency >= 40
  #                       8
  #                     elsif milestone_frequency >= 30
  #                       6
  #                     elsif milestone_frequency >= 20
  #                       4
  #                     elsif milestone_frequency >= 10
  #                       2
  #                     else
  #                       0
  #                     end
    
  #   # Highest score capability (max 10 points)
  #   highest_points = if avg_highest >= 60
  #                     10
  #                   elsif avg_highest >= 50
  #                     8
  #                   elsif avg_highest >= 40
  #                     6
  #                   elsif avg_highest >= 30
  #                     4
  #                   elsif avg_highest >= 20
  #                     2
  #                   else
  #                     0
  #                   end
    
  #   raw_rating = runs_points + sr_points + boundary_points + milestone_points + highest_points
  #   adjusted_rating = raw_rating * match_volume_factor
    
  #   [adjusted_rating.round(1), 100].min
  # end

  # def self.calculate_bowling_rating(player_data)
  #   total_wickets = 0
  #   total_runs_conceded = 0
  #   total_overs = 0
  #   total_matches = 0
  #   total_maidens = 0
  #   seasons_with_bowling_data = 0
    
  #   %w[4 5 6 7 8].each do |spl|
  #     matches = player_data["spl#{spl}_matches".to_sym].to_i
  #     wickets = player_data["spl#{spl}_wickets".to_sym].to_i
      
  #     if matches > 0 && wickets > 0
  #       total_wickets += wickets
  #       total_runs_conceded += player_data["spl#{spl}_bowling_runs".to_sym].to_i
  #       total_overs += player_data["spl#{spl}_overs".to_sym].to_f
  #       total_matches += matches
  #       total_maidens += player_data["spl#{spl}_maidens".to_sym].to_i
  #       seasons_with_bowling_data += 1
  #     end
  #   end
    
  #   return 0 if seasons_with_bowling_data == 0 || total_overs == 0
    
  #   # Calculate key metrics
  #   bowling_avg = total_wickets > 0 ? total_runs_conceded.to_f / total_wickets : 100
  #   economy_rate = total_runs_conceded.to_f / total_overs
  #   strike_rate = total_wickets > 0 ? (total_overs * 6).to_f / total_wickets : 100
  #   wickets_per_match = total_wickets.to_f / total_matches
  #   maiden_percentage = (total_maidens.to_f / total_overs) * 100
    
  #   # Calculate match volume factor
  #   match_volume_factor = calculate_match_volume_factor(total_matches)
    
  #   # Bowling rating calculation (out of 100)
  #   rating = 0
    
  #   # Wicket-taking ability (max 35 points)
  #   wickets_points = if wickets_per_match >= 2.0
  #                     35
  #                   elsif wickets_per_match >= 1.5
  #                     30
  #                   elsif wickets_per_match >= 1.0
  #                     25
  #                   elsif wickets_per_match >= 0.75
  #                     20
  #                   elsif wickets_per_match >= 0.5
  #                     15
  #                   elsif wickets_per_match >= 0.25
  #                     10
  #                   else
  #                     5
  #                   end
    
  #   # Economy rate (max 30 points)
  #   economy_points = if economy_rate <= 7.0
  #                     30
  #                   elsif economy_rate <= 8.0
  #                     25
  #                   elsif economy_rate <= 9.0
  #                     20
  #                   elsif economy_rate <= 10.0
  #                     15
  #                   elsif economy_rate <= 11.0
  #                     10
  #                   elsif economy_rate <= 12.0
  #                     5
  #                   else
  #                     0
  #                   end
    
  #   # Bowling average (max 20 points)
  #   average_points = if bowling_avg <= 15
  #                     20
  #                   elsif bowling_avg <= 20
  #                     16
  #                   elsif bowling_avg <= 25
  #                     12
  #                   elsif bowling_avg <= 30
  #                     8
  #                   elsif bowling_avg <= 35
  #                     4
  #                   else
  #                     0
  #                   end
    
  #   # Strike rate (max 10 points)
  #   strikerate_points = if strike_rate <= 12
  #                        10
  #                      elsif strike_rate <= 15
  #                        8
  #                      elsif strike_rate <= 18
  #                        6
  #                      elsif strike_rate <= 21
  #                        4
  #                      elsif strike_rate <= 24
  #                        2
  #                      else
  #                        0
  #                      end
    
  #   # Maiden overs (max 5 points)
  #   maiden_points = if maiden_percentage >= 15
  #                    5
  #                  elsif maiden_percentage >= 10
  #                    3
  #                  elsif maiden_percentage >= 5
  #                    1
  #                  else
  #                    0
  #                  end
    
  #   raw_rating = wickets_points + economy_points + average_points + strikerate_points + maiden_points
  #   adjusted_rating = raw_rating * match_volume_factor
    
  #   [adjusted_rating.round(1), 100].min
  # end

  # def self.calculate_all_ratings(player_data)
  #   batting_rating = calculate_batting_rating(player_data)
  #   bowling_rating = calculate_bowling_rating(player_data)
    
  #   {
  #     batting_rating: batting_rating,
  #     bowling_rating: bowling_rating,
  #     overall_rating: ((batting_rating + bowling_rating) / 2.0).round(1)
  #   }
  # end
  
  private
  
  def self.calculate_match_volume_factor(total_matches)
    case total_matches
    when 0..2
      0.6  # Heavy penalty for very few matches
    when 3..5
      0.8  # Moderate penalty
    when 6..10
      0.9  # Slight penalty
    when 11..15
      1.0  # Neutral - standard number of matches
    when 16..20
      1.1  # Bonus for good consistency
    else
      1.2  # Significant bonus for high match volume (>20)
    end
  end
end
