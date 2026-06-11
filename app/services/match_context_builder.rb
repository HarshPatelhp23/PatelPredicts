class MatchContextBuilder
  def build
    recent_matches = MatchSchedule.order(match_date: :desc).limit(5)
    upcoming_matches = MatchSchedule.where('match_date >= ?', Date.current).order(:match_date).limit(5)
    
    {
      recent_matches: recent_matches.map do |m|
        {
          name: m.match_name,
          date: m.match_date.strftime('%d %b %Y'),
          stadium: m.stadium,
          time: m.time
        }
      end,
      upcoming_matches: upcoming_matches.map do |m|
        {
          name: m.match_name,
          date: m.match_date.strftime('%d %b %Y'),
          stadium: m.stadium,
          time: m.time
        }
      end,
      total_matches: MatchSchedule.count,
      match_points: MatchPoint.joins(:team)
                             .select('match_points.match_name, teams.team_name, match_points.total_points')
                             .order(total_points: :desc)
                             .limit(10)
                             .map { |mp| { match: mp.match_name, team: mp.team_name, points: mp.total_points } }
    }
  end
end
