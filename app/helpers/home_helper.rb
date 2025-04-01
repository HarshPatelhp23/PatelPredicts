# frozen_string_literal: true

module HomeHelper
  def ordinal_suffix(number)
    case number % 10
    when 1 then 'st'
    when 2 then 'nd'
    when 3 then 'rd'
    else 'th'
    end
  end

  def show_point_difference(top_user_team, current_user_team)
    diff = (top_user_team.grand_total - top_user_team.penalty_points) - (current_user_team.grand_total - current_user_team.penalty_points)
    
    if top_user_team == current_user_team
      '' 
    elsif top_user_team != current_user_team && (top_user_team.grand_total - top_user_team.penalty_points) < (current_user_team.grand_total - current_user_team.penalty_points)
      " - #{diff * -1} points"
    elsif diff.zero?
      'Tied!!'
    else
      "+ #{diff} points"
    end
  end

  # def show_point_difference(top_user_team, current_user_team)
  #   diff = (top_user_team.grand_total - top_user_team.penalty_points) - (current_user_team.grand_total - current_user_team.penalty_points)
  #   if top_user_team == current_user_team
  #     'Congratulations!!!, you are in winning zone!'
  #   elsif top_user_team != current_user_team && top_user_team.grand_total < current_user_team.grand_total
  #     "is trailing by #{diff * -1} points "
  #   elsif diff.zero?
  #     'Tied!!'
  #   else
  #     "is leading by #{diff} points"
  #   end
  # end
end
