# frozen_string_literal: true

class Auction < ApplicationRecord
  validates :name, presence: true
  has_many :users, dependent: :destroy
  belongs_to :admin_user
  enum :status, %i[upcoming ongoing completed]
  # IPL_FIRST_WEEK_DATE = '18/03/2024'
  T20_WC_FIRST_WEEK_DATE = '02/06/2024'

  def self.ransackable_attributes(_auth_object = nil)
    %w[admin_user_id created_at id name starts_at status teams_count updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[admin_user users]
  end
end
