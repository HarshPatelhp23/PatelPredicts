class TeamContextBuilder
  def build
    teams_data = Team.joins(:user)
                    .select('teams.team_name, users.username, users.remaining_purse, users.grand_total, users.penalty_points')
    
    {
      total_teams: Team.count,
      teams_info: teams_data.map do |t|
        {
          name: t.team_name,
          owner: t.username,
          remaining_purse: format_currency(t.remaining_purse),
          total_points: t.grand_total,
          penalty_points: t.penalty_points
        }
      end,
      leaderboard: teams_data.order('users.grand_total DESC').limit(10).map.with_index do |t, index|
        {
          position: index + 1,
          team: t.team_name,
          owner: t.username,
          points: t.grand_total,
          remaining_purse: format_currency(t.remaining_purse)
        }
      end
    }
  end
  
  private
  
  def format_currency(amount)
    return '₹0' if amount.nil? || amount.zero?
    
    if amount >= 10000000 # 1 crore
      "₹#{(amount / 10000000.0).round(2)} Cr"
    elsif amount >= 100000 # 1 lakh
      "₹#{(amount / 100000.0).round(2)} L"
    else
      "₹#{amount.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}"
    end
  end
end
