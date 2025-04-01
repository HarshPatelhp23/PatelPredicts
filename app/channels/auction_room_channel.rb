# frozen_string_literal: true

class AuctionRoomChannel < ApplicationCable::Channel
  def subscribed
    stream_from 'auction_room_channel'
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
