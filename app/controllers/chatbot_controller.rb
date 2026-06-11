# app/controllers/chatbot_controller.rb
class ChatbotController < ApplicationController
  before_action :authenticate_user!
  
  def index
    @user_stats = get_user_dashboard_stats
    @quick_stats = get_quick_stats
  end
  
  def chat
    user_message = params[:message]
    
    begin
      bot_message = ChatbotService.generate_text(user_message)
      
      render json: { 
        success: true, 
        message: bot_message[:formatted_message]
      }
    rescue => e
      Rails.logger.error "Chatbot error: #{e.message}"
      render json: { 
        success: false, 
        message: "Sorry, I'm having trouble processing your request right now. Please try again." 
      }
    end
  end
  
  private
  
  def get_user_dashboard_stats
    user_team = current_user.teams.first
    
    {
      user_name: current_user.username,
      team_name: user_team&.team_name || "No Team",
      total_points: current_user.grand_total || 0,
      remaining_purse: format_currency(current_user.remaining_purse || 0),
      penalty_points: current_user.penalty_points || 0,
      players_count: user_team&.players&.count || 0,
      rank: calculate_user_rank
    }
  end
  
  def get_quick_stats
    {
      total_players: Player.count,
      foreign_players: Player.where(foreigner: true).count,
      total_teams: Team.count,
      upcoming_matches: MatchSchedule.where('match_date >= ?', Date.current).count,
      active_auctions: Auction.where(status: 'active').count
    }
  end
  
  def calculate_user_rank
    users_with_higher_points = User.where('grand_total > ?', current_user.grand_total || 0).count
    users_with_higher_points + 1
  end
  
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
