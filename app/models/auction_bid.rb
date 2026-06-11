class AuctionBid < ApplicationRecord
  belongs_to :auction
  belongs_to :team
  belongs_to :player
  
  # Validations
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :auction_id, :team_id, :player_id, presence: true
  
  # Callbacks
  after_create :update_team_purse
  after_create :notify_participants
  
  # Scopes
  scope :sold, -> { where(sold: true) }
  scope :online_bids, -> { where(online_bid: true) }
  scope :by_auction, ->(auction_id) { where(auction_id: auction_id) }
  scope :by_team, ->(team_id) { where(team_id: team_id) }
  
  # Amount in crores for display
  def amount_in_crores
    amount.to_f / 10000000
  end
  
  # Amount in lakhs for display
  def amount_in_lakhs
    amount.to_f / 100000
  end
  
  # Format amount for display
  def display_amount
    if amount >= 10000000
      "₹#{amount_in_crores.round(2)} Cr"
    else
      "₹#{amount_in_lakhs.round(2)} L"
    end
  end
  
  private
  
  def update_team_purse
    if sold && team.present?
      team.remaining_purse -= amount
      team.save
    end
  end
  
  def notify_participants
    # implement ActionCable notifications here if needed
    # For now, just log
    Rails.logger.info "AuctionBid created: Player #{player_id} sold to Team #{team_id} for #{display_amount}"
  end
end
