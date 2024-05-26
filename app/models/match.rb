# frozen_string_literal: true

class Match < ApplicationRecord
  belongs_to :player, optional: true
  belongs_to :team
  after_save :calculate_grand_total
  after_save :calculate_one_match_point
  after_save :update_player_point
  after_save :final_total_user_points

  def self.ransackable_attributes(_auth_object = nil)
    %w[created_at id match_name player_id points updated_at team_id auction_id]
  end

  def self.ransackable_associations(_auth_object = nil)
    []
  end

  def calculate_grand_total
    points = team.matches.pluck(:points)
    grand_total = points.sum
    team.user.update(grand_total:)
  end

  def calculate_one_match_point
    match_point = MatchPoint.find_or_create_by(match_name:, team_id: team.id)
    points = team&.matches&.where(match_name:)&.pluck(:points)
    match_point.update(total_points: points.sum)
  end

  def update_player_point
    total_points = points + (player&.points || 0)
    player&.update(points: total_points)
  end

  def final_total_user_points
    final_total_points = team.user.calculate_final_total_points
    team.user.update(final_total_points:)
  end
end
