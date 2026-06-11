# frozen_string_literal: true

class AuctionRoom < ApplicationRecord
  FIXED_TEAM_ORDER = [
      'Harsh',
      'Parth Gandhi',
      'Haardam Doshi',
      'Yash Agrawal',
      'Sagar Thakkar'
    ].freeze
  enum amount_unit: { lakhs: 0, crores: 1 }
  belongs_to :user
  belongs_to :auction_player

  after_create  :set_player_name, :set_player_status
  after_create  :update_purse

  # FIX: Use after_create_commit instead of after_save.
  # after_save fires on EVERY save — including the update_columns calls above —
  # which caused two broadcasts per player purchase.
  after_create_commit :broadcast_new_auction_room

  AUCTIONROOMCODE = Rails.application.credentials.dig(:auction_room, :code)

  def current_integer_amount
    return nil if amount.nil? || amount_unit.nil?

    conversion_factor = case amount_unit.downcase
                        when 'lakhs'  then 100_000
                        when 'crores' then 10_000_000
                        else raise "Unsupported unit: #{amount_unit}"
                        end

    (amount * conversion_factor).round
  end

  def is_a_captain?
    player_name == user.slug
  end

  private

  def broadcast_new_auction_room
    Rails.logger.info "Broadcasting new auction room for user #{user.id}"

    # FIXED TEAM ORDER — positions never change regardless of winning %
    # Order: 1.Spartans(Harsh), 2.Scorchers(Parth), 3.Strikers(Haardam), 4.Stunners(Yash), 5.Smashers(Sagar)

    users_in_fixed_order = FIXED_TEAM_ORDER.map do |username|
      User.find_by(username:)
    end.compact

    # Build ranking data in FIXED positions (rank = fixed slot, not by winning %)
    # The rank here is just the display position — it never reorders.
    ranking_data = users_in_fixed_order.each_with_index.map do |u, index|
      {
        user_id: u.id,
        rank: index + 1,
        winning_percentage: TeamSkillEvaluator.calculate_winning_chances(u).to_f,
        team_tag: u.username.split.first
      }
    end

    data = {
      user_id:           user.id,
      player_name:       auction_player.name,
      remaining_purse:   CurrencyFormatter.format(user.reload.remaining_purse),
      batting:           auction_player.batting,
      bowling:           auction_player.bowling,
      team_batting:      TeamSkillEvaluator.calculate_strength(user, 'batting'),
      team_bowling:      TeamSkillEvaluator.calculate_strength(user, 'bowling'),
      winning_percentage: TeamSkillEvaluator.all_team_winning_chances,
      purchase_insight:  set_purchase_insight_image,
      notification:      notification,
      rankings:          ranking_data
      # NOTE: not sending html — JS builds the card locally with correct at- classes
    }

    ActionCable.server.broadcast('auction_room_channel', data)
  end

  def update_purse
    updated_purse = user.remaining_purse - current_integer_amount.to_i
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
      TeamSkillEvaluator.categorize_buy(
        auction_player.base_price,
        auction_player.total_skill,
        current_integer_amount
      )
    end
  end

  def notification
    team = map_team_with_captain[user.username]
    if is_a_captain?
      "Team #{team} proudly welcomes our Captain:- #{user.slug} 👑"
    else
      "#{auction_player.name.upcase} is sold to team #{team} for #{CurrencyFormatter.format(current_integer_amount)}"
    end
  end

  def map_team_with_captain
    {
      'Haardam Doshi'  => 'Strikers',
      'Yash Agrawal'   => 'Stunners',
      'Parth Gandhi'   => 'Scorchers',
      'Harsh'          => 'Spartans',
      'Sagar Thakkar'  => 'Smashers'
    }
  end
end


# # frozen_string_literal: true

# class AuctionRoom < ApplicationRecord
#   enum amount_unit: { lakhs: 0, crores: 1 }
#   belongs_to :user
#   belongs_to :auction_player
#   # has_one_attached :profile_photo
#   after_create :set_player_name, :set_player_status
#   after_save :update_purse
#   after_save :broadcast_new_auction_room
#   AUCTIONROOMCODE = Rails.application.credentials.dig(:auction_room, :code)

#   def current_integer_amount
#     return nil if amount.nil? || amount_unit.nil?

#     conversion_factor = case amount_unit.downcase
#                         when 'lakhs'
#                           100_000
#                         when 'crores'
#                           10_000_000
#                         else
#                           raise "Unsupported unit: #{amount_unit}"
#                         end

#     (amount * conversion_factor).round
#   end

#   def is_a_captain?
#     return true if player_name == user.slug

#     false
#   end

#   private

#   # def broadcast_new_auction_room
#   #   # Render HTML for the new player row
#   #   player_html = ApplicationController.render(
#   #     partial: 'auctions/auction_room',
#   #     locals: { auction_room: self }
#   #   )
#   #   # Prepare additional data for broadcast
#   #   data = {
#   #     player_html:,
#   #     user_id:,
#   #     remaining_purse: CurrencyFormatter.format(user.remaining_purse),
#   #     player_name: auction_player.name,
#   #     batting: auction_player.batting,
#   #     bowling: auction_player.bowling,
#   #     team_batting: TeamSkillEvaluator.calculate_strength(user, 'batting'),
#   #     team_bowling: TeamSkillEvaluator.calculate_strength(user, 'bowling'),
#   #     winning_percentage: TeamSkillEvaluator.all_team_winning_chances,
#   #     max_bid: TeamSkillEvaluator.all_team_max_bid,
#   #     purchase_insight: set_purchase_insight_image,
#   #     notification:
#   #   }

#   #   # Broadcast data to the ActionCable channel
#   #   ActionCable.server.broadcast('auction_room_channel', data)
#   # end

#   #CURRENT WORKING CODE
#   # def broadcast_new_auction_room
#   #   Rails.logger.info "Broadcasting new auction room for user #{user.id}"
#   #   rendered_html = ApplicationController.render(
#   #     partial: 'auctions/auction_room',
#   #     locals: { auction_room: self }
#   #   )

#   #   data = {
#   #     user_id: user.id,
#   #     player_name: auction_player.name,
#   #     remaining_purse: CurrencyFormatter.format(user.remaining_purse),
#   #     batting: auction_player.batting,
#   #     bowling: auction_player.bowling,
#   #     team_batting: TeamSkillEvaluator.calculate_strength(user, 'batting'),
#   #     team_bowling: TeamSkillEvaluator.calculate_strength(user, 'bowling'),
#   #     winning_percentage: TeamSkillEvaluator.all_team_winning_chances,
#   #     max_bid: TeamSkillEvaluator.all_team_max_bid,
#   #     purchase_insight: set_purchase_insight_image,
#   #     notification: notification,
#   #     html: rendered_html # include this
#   #   }

#   #   ActionCable.server.broadcast('auction_room_channel', data)
#   # end


#   def broadcast_new_auction_room
#     Rails.logger.info "Broadcasting new auction room for user #{user.id}"
#     rendered_html = ApplicationController.render(
#       partial: 'auctions/auction_room',
#       locals: { auction_room: self }
#     )

#     # Get all users sorted by winning chances
#     users = User.captains.sort_by { |user| TeamSkillEvaluator.calculate_winning_chances(user) }.reverse
    
#     # Create ranking data with order
#     ranking_data = users.each_with_index.map do |user, index|
#       {
#         user_id: user.id,
#         rank: index + 1,
#         winning_percentage: TeamSkillEvaluator.calculate_winning_chances(user),
#         team_tag: user.username.split.first
#       }
#     end

#     data = {
#       user_id: user.id,
#       player_name: auction_player.name,
#       remaining_purse: CurrencyFormatter.format(user.remaining_purse),
#       batting: auction_player.batting,
#       bowling: auction_player.bowling,
#       team_batting: TeamSkillEvaluator.calculate_strength(user, 'batting'),
#       team_bowling: TeamSkillEvaluator.calculate_strength(user, 'bowling'),
#       winning_percentage: TeamSkillEvaluator.all_team_winning_chances,
#       max_bid: TeamSkillEvaluator.all_team_max_bid,
#       purchase_insight: set_purchase_insight_image,
#       notification: notification,
#       html: rendered_html,
#       # Add ranking data for live reordering
#       rankings: ranking_data
#     }

#     ActionCable.server.broadcast('auction_room_channel', data)
#   end

#   def update_purse
#     updated_purse = user.remaining_purse - current_integer_amount.to_i
#     user.update_columns(remaining_purse: updated_purse)
#   end

#   def set_player_name
#     update_columns(player_name: auction_player.name)
#   end

#   def set_player_status
#     auction_player.update_columns(sold: true)
#   end

#   def set_purchase_insight_image
#     if is_a_captain?
#       'captain'
#     else
#       TeamSkillEvaluator.categorize_buy(auction_player.base_price,
#                                         auction_player.total_skill, current_integer_amount)
#     end
#   end

#   def notification
#     team = map_team_with_captain[user.username]
#     if is_a_captain?
#       "Team #{team} proudly welcomes our Captain:- #{user.slug} 👑"
#     else
#       "#{auction_player.name.upcase} is sold to team- #{team} in #{CurrencyFormatter.format(current_integer_amount)}"
#     end
#   end

#   def map_team_with_captain
#     {
#       'Haardam Doshi' => 'Strikers',
#       'Yash Agrawal' => 'Stunners',
#       'Parth Gandhi' => 'Scorchers',
#       'Harsh' => 'Spartans',
#       'Sagar Thakkar' => 'Smashers',
#     }
#   end
# end
