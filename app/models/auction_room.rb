# frozen_string_literal: true

class AuctionRoom < ApplicationRecord
  enum amount_unit: { lakhs: 0, crores: 1 }
  belongs_to :user
  belongs_to :auction_player
  # has_one_attached :profile_photo
  after_create :set_player_name, :set_player_status
  after_save :update_purse
  after_save :broadcast_new_auction_room
  AUCTIONROOMCODE = Rails.application.credentials.dig(:auction_room, :code)

  def current_integer_amount
    return nil if amount.nil? || amount_unit.nil?

    conversion_factor = case amount_unit.downcase
                        when 'lakhs'
                          100_000
                        when 'crores'
                          10_000_000
                        else
                          raise "Unsupported unit: #{amount_unit}"
                        end

    (amount * conversion_factor).round
  end

  def is_a_captain?
    return true if player_name == user.slug

    false
  end

  private

  def broadcast_new_auction_room
    # Render HTML for the new player row
    player_html = ApplicationController.render(
      partial: 'auctions/auction_room',
      locals: { auction_room: self }
    )
    # Prepare additional data for broadcast
    data = {
      player_html:,
      user_id:,
      remaining_purse: CurrencyFormatter.format(user.remaining_purse),
      player_name: auction_player.name,
      batting: auction_player.batting,
      bowling: auction_player.bowling,
      team_batting: TeamSkillEvaluator.calculate_strength(user, 'batting'),
      team_bowling: TeamSkillEvaluator.calculate_strength(user, 'bowling'),
      winning_percentage: TeamSkillEvaluator.all_team_winning_chances,
      max_bid: TeamSkillEvaluator.all_team_max_bid,
      purchase_insight: set_purchase_insight_image,
      notification:
    }

    # Broadcast data to the ActionCable channel
    ActionCable.server.broadcast('auction_room_channel', data)
  end

  def update_purse
    updated_purse = user.remaining_purse - current_integer_amount
    user.update_columns(remaining_purse: updated_purse)
  end

  def set_player_name
    update_columns(player_name: auction_player.name)
  end

  def set_player_status
    auction_player.update_columns(sold: true)
  end

  def set_purchase_insight_image
    if is_a_captain?
      'captain'
    else
      TeamSkillEvaluator.categorize_buy(auction_player.base_price,
                                        auction_player.total_skill, current_integer_amount)
    end
  end

  def notification
    if is_a_captain?
      "Welcome, Captain-#{user.slug} 👑"
    else
      "#{auction_player.name.upcase} is sold to team- #{user.username} in #{CurrencyFormatter.format(current_integer_amount)}"
    end
  end
end
