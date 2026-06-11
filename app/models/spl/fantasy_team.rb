module Spl
  class FantasyTeam < ApplicationRecord
    self.table_name = 'spl_fantasy_teams'
    
    has_and_belongs_to_many :auction_players, 
      join_table: :fantasy_teams_auction_players,
      foreign_key: :spl_fantasy_team_id,
      association_foreign_key: :auction_player_id
    
    belongs_to :spl_user, class_name: 'Spl::User'
    belongs_to :captain, class_name: 'AuctionPlayer', optional: true
    belongs_to :vice_captain, class_name: 'AuctionPlayer', optional: true
    
    # validates :playing11, presence: true
    
    # Fix: Don't alias playing11 to itself (creates infinite loop)
    # Remove this line: alias_method :playing11, :playing11_players
    
    # def playing11_players
    #   AuctionPlayer.where(id: playing11)
    # end
    
    # # If you want to use playing11 as a method that returns players:
    # def playing11
    #   playing11_players
    # end
  end
end