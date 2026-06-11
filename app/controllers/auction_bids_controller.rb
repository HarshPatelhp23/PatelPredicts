class AuctionBidsController < ApplicationController
	def create
		players_team_record = PlayersTeam.new(player_id: params[:auction_bid][:player_id],
																					team_id: params[:auction_bid][:team_id],
																					sold_price: params[:auction_bid][:amount])
    respond_to do |format|
      if players_team_record.save
        no_of_players = players_team_record&.team&.players_teams&.count
        # Update team purse
        team = players_team_record.team
        team.remaining_purse -= players_team_record.sold_price
        team.save
        
        format.json { 
          render json: { 
              success: true, 
              remaining_purse: team.remaining_purse,
              total_purse: team.total_purse,
              no_of_players:
          } 
        }
      else
        format.json { 
          render json: { 
              success: false, 
              error: @auction_bid.errors.full_messages.join(', ') 
          }, 
          status: :unprocessable_entity 
        }
      end
    end
	end
end
