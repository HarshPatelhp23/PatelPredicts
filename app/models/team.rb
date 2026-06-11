# frozen_string_literal: true

class Team < ApplicationRecord
  extend FriendlyId
  friendly_id :team_name, use: :slugged
  validates :team_name, presence: true, uniqueness: true
  # has_many :players, dependent: :destroy
  # has_and_belongs_to_many :players
  has_one_attached :profile_image
  has_many :players_teams
  has_many :players, through: :players_teams
  has_many :matches, dependent: :destroy
  has_many :match_points, dependent: :destroy
  has_many :weekly_user_teams
  has_many :player_perfomace_points, dependent: :destroy
  belongs_to :user, optional: true
  belongs_to :auction, optional: true


  validates :team_name, presence: true, uniqueness: true

  def to_param
    slug
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[created_at id team_name updated_at user_id matches_id match_points_id]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[players user]
  end

  def update_team_name
    update(team_name: user.username)
  end

  # USE ME IN NEXT SEASON
  # def total_bench_points
  #   players_teams.sum(:bench_points)
  # end

  def total_bench_points
    points = 0
    players.each do |player|
      points+= player.matches.sum(:bench_points)
    end
    points
  end
end
