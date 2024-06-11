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

  def show_point_difference(top_user, current_user)
    diff = top_user.final_total_points - current_user.final_total_points
    if diff.zero?
      'Tied!!'
    else
      "is leading by #{diff} points"
    end
  end
end
