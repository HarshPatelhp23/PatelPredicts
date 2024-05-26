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
end
