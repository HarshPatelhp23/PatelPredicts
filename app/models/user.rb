# frozen_string_literal: true

class User < ApplicationRecord
  extend FriendlyId
  friendly_id :username, use: :slugged
  validates :username, presence: true, uniqueness: true
  validates :password, confirmation: true
  validates :password_confirmation, presence: true, if: :password_required?
  has_one :team, dependent: :destroy
  has_many :players, through: :teams
  has_many :weekly_user_teams, dependent: :destroy
  # has_many :notifications, as: :recipient, dependent: :destroy
  belongs_to :auction, optional: true
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  before_save :update_final_total_points, if: -> { penalty_points_changed? && !new_record? }
  before_save :update_team_name, if: -> { username_changed? }
  scope :pool_users, ->(user) { where(auction_id: user.auction_id) }

  def to_param
    slug
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[email grand_total]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[auction team]
  end

  def password_required?
    new_record? || password.present?
  end

  def rankings_data
    data = {}
    @matches = Match.where(auction_id:).order(created_at: :asc).uniq
    @matches.each do |match|
      data[match.match_name] = find_poistion_in_match(match.match_name)
    end
    data
  end

  def find_poistion_in_match(match_name)
    team_ranking = MatchPoint.where(match_name:).order(total_points: :desc).pluck(:team_id)
    team_ranking.index(team.id) + 1
  end

  def calculate_final_total_points
    grand_total - penalty_points
  end

  def update_final_total_points
    self.final_total_points = calculate_final_total_points
  end

  def update_team_name
    team&.update_team_name
  end

  def data; end
end
