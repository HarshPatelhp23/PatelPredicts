# frozen_string_literal: true

class Team < ApplicationRecord
  extend FriendlyId
  friendly_id :team_name, use: :slugged
  validates :team_name, presence: true, uniqueness: true
  has_many :players, dependent: :destroy
  has_many :matches, dependent: :destroy
  has_many :match_points, dependent: :destroy
  belongs_to :user, optional: true

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
end
