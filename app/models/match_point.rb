# frozen_string_literal: true

class MatchPoint < ApplicationRecord
  belongs_to :team
  validates :total_points, presence: true

  scope :leader_of_match, ->(match_name) { where(match_name:).order(total_points: :desc).first.team.user.username }
  scope :leader_points_of_match, ->(match_name) { where(match_name:).order(total_points: :desc).first.total_points }

  def self.ransackable_attributes(_auth_object = nil)
    %w[created_at id team_id total_points updated_at match_name]
  end

  def self.ransackable_associations(_auth_object = nil)
    ['team']
  end

  def self.find_poistion_in_match(match_name, user)
    team_ranking = where(match_name:).order(total_points: :desc).pluck(:team_id)
    team_ranking.index(user.team.id)&.+ 1
  end

  def self.find_points_in_match(match_name, user)
    where(match_name:, team: user&.team).first&.total_points
  end
end
