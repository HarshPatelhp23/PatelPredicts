# frozen_string_literal: true

class AuctionsController < ApplicationController
  def show
    @auction = Auction.find(params[:id])
  end

  def new
    @auction = Auction.new
  end

  def create
    @auction = Auction.create(auction_params)
  end

  private

  def auction_params
    params.require(:auction).permit(:name, :starts_at, :teams_count, :admin_user_id)
  end
end
