class DatabaseContextBuilder
  def initialize(user)
    @user = user
  end
  
  def build_context(message)
    message_lower = message.downcase
    context = {}
    
    context[:players] = build_players_context(message_lower) if player_query?(message_lower)
    context[:teams] = build_teams_context if team_query?(message_lower)
    context[:matches] = build_matches_context if match_query?(message_lower)
    context[:auctions] = build_auction_context if auction_query?(message_lower)
    context[:user_stats] = build_user_context if user_query?(message_lower)
    
    context
  end
  
  private
  
  def player_query?(message)
    message.match?(/player|foreign|batsman|bowler|wicket|keeper|role/)
  end
  
  def team_query?(message)
    message.match?(/team|squad|purse|budget|owner/)
  end
  
  def match_query?(message)
    message.match?(/match|point|performance|score|schedule/)
  end
  
  def auction_query?(message)
    message.match?(/auction|bid|sold|price|unsold/)
  end
  
  def user_query?(message)
    message.match?(/my team|my player|my point|leaderboard|my performance/)
  end
  
  def build_players_context(message)
    PlayerContextBuilder.new.build(message)
  end
  
  def build_teams_context
    TeamContextBuilder.new.build
  end
  
  def build_matches_context
    MatchContextBuilder.new.build
  end
  
  def build_auction_context
    AuctionContextBuilder.new.build
  end
  
  def build_user_context
    UserContextBuilder.new(@user).build
  end
end
