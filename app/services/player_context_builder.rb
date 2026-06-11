class PlayerContextBuilder
  def build(message)
    data = {}
    
    # Foreign players
    if message.include?('foreign')
      foreign_players = Player.where(foreigner: true)
                             .select(:name, :role, :team_name, :sold_price)
      
      data[:foreign_players] = foreign_players.map do |player|
        {
          name: player.name,
          role: get_role_name(player.role),
          team: player.team_name,
          price: player.sold_price,
          points: player.players_teams.last&.points
        }
      end
      data[:foreign_count] = foreign_players.count
    end
    
    # Role-based queries
    if message.match?(/batsman|batsmen/)
      data[:batsmen] = Player.where(role: 1).order(points: :desc).limit(10)
                            .pluck(:name, :team_name, :points)
    end
    
    if message.match?(/bowler/)
      data[:bowlers] = Player.where(role: 3).order(points: :desc).limit(10)
                            .pluck(:name, :team_name, :points)
    end
    
    if message.match?(/wicket.*keeper|keeper/)
      data[:wicket_keepers] = Player.where(role: 0).order(points: :desc)
                                   .pluck(:name, :team_name, :points)
    end
    
    if message.match?(/all.*rounder/)
      data[:all_rounders] = Player.where(role: 2).order(points: :desc).limit(10)
                                 .pluck(:name, :team_name, :points)
    end
    
    # Top performers
    if message.match?(/top|best|highest|leading/)
      data[:top_players] = Player.order(points: :desc).limit(10)
                                .pluck(:name, :points, :team_name, :role)
                                .map { |p| [p[0], p[1], p[2], get_role_name(p[3])] }
    end
    
    # Basic stats
    data[:total_players] = Player.count
    data[:players_by_role] = {
      wicket_keepers: Player.where(role: 0).count,
      batsmen: Player.where(role: 1).count,
      all_rounders: Player.where(role: 2).count,
      bowlers: Player.where(role: 3).count
    }
    
    data
  end
  
  private
  
  def get_role_name(role_id)
    case role_id
    when 0 then 'Wicket Keeper'
    when 1 then 'Batsman'
    when 2 then 'All Rounder'
    when 3 then 'Bowler'
    else 'Unknown'
    end
  end
end
