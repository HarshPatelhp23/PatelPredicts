# frozen_string_literal: true

class User < ApplicationRecord
  extend FriendlyId
  friendly_id :username, use: :slugged
  validates :username, presence: true, uniqueness: true
  validates :password, confirmation: true
  validates :password_confirmation, presence: true, if: :password_required?
  # validates :team_id, uniqueness: { scope: :auction_id, message: "You already have a team for this auction." }
  # has_one :team, dependent: :destroy
  has_many :teams, dependent: :destroy
  has_many :weekly_user_teams, dependent: :destroy
  has_many :auction_rooms, dependent: :destroy
  has_many :auction_players, through: :auction_rooms, dependent: :destroy
  # has_many :notifications, as: :recipient, dependent: :destroy
  has_many :user_auctions
  has_many :auctions, through: :user_auctions
  has_many :push_subscriptions, dependent: :destroy
  has_many :device_tokens, dependent: :destroy
  has_many :firebase_registrations, dependent: :destroy
  has_one_attached :profile_picture
  # belongs_to :auction, optional: true
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :timeoutable

  before_save :update_final_total_points, if: -> { penalty_points_changed? && !new_record? }
  before_save :update_team_name, if: -> { username_changed? }
  # scope :pool_users, ->(user) { where(auction_id: user.auction_id) }
  scope :captains, -> { where(captain: true) }

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

  def rankings_data(auction_id, team_id)
    data = {}
    @matches = Match.where(auction_id:, team_id:).order(created_at: :asc).uniq
    @matches.each do |match|
      data[match.match_name] = find_position_in_match(match.match_name, team_id, auction_id)
    end
    data
  end

  def find_position_in_match(match_name, team_id, auction_id)
    ranking = MatchPoint
      .joins(:team)
      .where(teams: { auction_id: auction_id }, match_name: match_name)
      .group(:team_id)
      .order('MAX(total_points) DESC')
      .pluck(:team_id)
      .index(team_id)

    ranking ? ranking + 1 : nil
  end

  # def find_poistion_in_match(match_name, team_id, auction_id)
  #   # team_ranking = MatchPoint.where(match_name:, auction_id:).order(total_points: :desc).pluck(:team_id)
  #   team_ranking = MatchPoint.joins(:team)
  #                             .where(match_name:, teams: { auction_id:})
  #                             .order(total_points: :desc).pluck(:team_id)
  #   team_ranking.index(team_id) + 1
  # end

  def calculate_final_total_points
    grand_total - penalty_points
  end

  def update_final_total_points
    self.final_total_points = calculate_final_total_points
  end

  def update_team_name
    teams.map { |team| team.update_team_name }
  end

  def data; end

  def captain_player
    auction_players.where(name: slug).count
  end
end
