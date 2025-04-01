module BonusPoints
  extend ActiveSupport::Concern

  included do
    after_commit :assign_bonus_points, on: [:create]
  end

  def assign_bonus_points
    calculate_batting_bonus_field_points
    calculate_bowling_bonus_field_points
    calculate_eco_bonus
    calculate_catch_bonus
  end

  def all_bonus_points
    bonus_fields = %i[bonus_100 bonus_50 bonus_30 bonus_5w bonus_4w bonus_3w catch_bonus eco_bonus strike_rate_bonus]
    bonus_points = bonus_fields.sum { |field| self[field].to_i } 
    # players_team_record = PlayersTeam.where(team:, player:)&.first
    # points = bonus_points + players_team_record.points
    # players_team_record.update_columns(points:)
  end


  private

  def calculate_batting_bonus_field_points
    (bonus_runs_points || 0 ) + (strike_rate_bonus_points || 0)
  end

  def bonus_runs_points
    bonus_fields = { bonus_100: 100, bonus_50: 50, bonus_30: 30 }
    sorted_fields = bonus_fields.sort_by { |_field, threshold| -threshold }
    selected_field = sorted_fields.find { |_field, threshold| runs >= threshold }
    
    if selected_field
      field, _threshold = selected_field
      rejected_fields = sorted_fields.reject { |f, _| f == field }.map(&:first)
      points = PlayerPerfomacePoint::POINTS_EVALUATION[field.to_sym]
      update_columns(field => points, **rejected_fields.to_h { |rf| [rf, 0] })
      points
    else
      0
    end
  end

  def strike_rate_bonus_points
    return 0 unless balls_faced > 15

    points = case strike_rate.to_f
             when strike_rate.to_f < 100
              -6
             when 135..150
              2
             when 150..170
              4
             when 170..200
              6
             when 200..600
              8
             else
              0
             end

    update_columns(strike_rate_bonus: points) if points > 0
    points
  end

  def calculate_bowling_bonus_field_points
    bonus_fields = { bonus_5w: 5, bonus_4w: 4, bonus_3w: 3 }
    sorted_fields = bonus_fields.sort_by { |_field, threshold| -threshold }
    selected_field = sorted_fields.find { |_field, threshold| wickets >= threshold }

    if selected_field
      field, _threshold = selected_field
      points = PlayerPerfomacePoint::POINTS_EVALUATION[field.to_sym]
      rejected_fields = sorted_fields.reject { |f, _| f == field }.map(&:first)
      update_columns(field => points, **rejected_fields.to_h { |rf| [rf, 0] })
    else
      0
    end
  end

  def calculate_catch_bonus
    points = case catches
             when 3
               5
             when 4
               8
             when 5..10
               10
             else
               0
             end

    update_columns(catch_bonus: points) if points > 0
    points
  end

  def calculate_eco_bonus
    return 0 unless overs_bowled > 2

    points = case eco.to_f
             when 0..3
               8
             when 3..5
               4
             when 5..6
               2
             when 9..12
              -4
             when 12..40
              -8
             else
               0
             end
    update_columns(eco_bonus: points)
    points
  end

  # IPL
  # def calculate_eco_bonus
  #   return 0 unless overs_bowled > 5

  #   points = case eco
  #            when 0..6
  #              4
  #            when 6..8
  #              2
  #            when 11..12
  #              -2
  #            when 12..40
  #              -4
  #            else
  #              0
  #            end
  #   update_columns(eco_bonus: points) if points > 0
  #   points
  # end
end