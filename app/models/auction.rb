# frozen_string_literal: true

class Auction < ApplicationRecord
  validates :name, presence: true
  has_many :user_auctions
  has_many :users, through: :user_auctions
  has_many :teams
  belongs_to :admin_user
  enum :status, %i[upcoming ongoing completed]
  IPL_FIRST_WEEK_DATE = '23/03/2026'
  # T20_WC_FIRST_WEEK_DATE = '02/06/2024'
  # CT_FIRST_WEEK_DATE = '17/02/2025'

  def self.ransackable_attributes(_auth_object = nil)
    %w[admin_user_id created_at id name starts_at status teams_count updated_at user_auctions_id_eq]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[admin_user users teams]
  end
end
