module Spl
  class User < ApplicationRecord
    # Include default devise modules. Others available are:
    # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
    devise :database_authenticatable, :registerable,
           :recoverable, :rememberable, :validatable

    
    has_one :fantasy_team, class_name: 'Spl::FantasyTeam', foreign_key: 'spl_user_id', dependent: :destroy
    # has_many :fantasy_teams, class_name: 'Spl::FantasyTeam', foreign_key: 'spl_user_id'
    has_many :auction_players, through: :fantasy_team
    validates :name, presence: true
    # validates :team_name, uniqueness: { scope: :category }, allow_blank: true
    
    after_create :create_default_fantasy_team


    def otp_verified?
      SplOtp.where(email:).exists?
    end

    def calculate_total_points
      return 0 unless fantasy_team&.playing11.present?
      
      total = 0
      
      fantasy_team.playing11.each do |player_id|
        player = AuctionPlayer.find(player_id)
        points = player.points.to_i
        total += points
      end
      
      # Add captain bonus (2x - already counted once, so add 1x extra)
      if fantasy_team.captain_id
        captain_points = fantasy_team.captain&.points.to_i
        total += captain_points # 1x extra for 2x total
      end
      
      # Add vice captain bonus (1.5x - already counted once, so add 0.5x extra)
      if fantasy_team.vice_captain_id
        vc_points = fantasy_team.vice_captain&.points.to_i
        total += (vc_points * 0.5).to_i
      end
      
      total
    end
    
    def update_total_points!
      new_total = calculate_total_points
      update_column(:total_points, new_total)
    end
    
    private

    
    def create_default_fantasy_team
      build_fantasy_team(team_name: "#{self.name}'s Team").save
    end
  end
end
