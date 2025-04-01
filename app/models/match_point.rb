# frozen_string_literal: true

class MatchPoint < ApplicationRecord
  belongs_to :team
  validates :total_points, presence: true

  scope :leader_of_match, ->(match_name, auction, user) { joins(:team).where(match_name:, teams: { auction: }).order(total_points: :desc).first.team.user.username }
  scope :leader_points_of_match, ->(match_name, auction, user) { joins(:team).where(match_name:, teams: { auction: }).order(total_points: :desc).first.total_points }

  def self.ransackable_attributes(_auth_object = nil)
    %w[created_at id team_id total_points updated_at match_name]
  end

  def self.ransackable_associations(_auth_object = nil)
    ['team']
  end

  class << self

    # def find_poistion_in_match(match_name, team_id, auction)
    #   pool_team_ids = auction.teams.pluck(:id)
    #   team_ranking = MatchPoint.where(team_id: pool_team_ids, match_name:).order(total_points: :desc).pluck(:team_id)
    #   team_ranking.index(team_id)&.+ 1
    # end
# ========================================================================

    def find_position_in_match(match_name, team_id, auction)
      ranking = MatchPoint
        .joins(:team)
        .where(teams: { auction_id: auction.id }, match_name: match_name)
        .group(:team_id)
        .order('MAX(total_points) DESC')
        .pluck(:team_id)
        .index(team_id)

      ranking ? ranking + 1 : nil
    end

    def find_points_in_match(match_name, team_id, auction)
      team = Team.find(team_id)
      team.match_points
          .where(match_name: match_name)
          .order(created_at: :desc)
          .limit(1)
          .pluck(:total_points)
          .first
    end
# ====================================================================
    # def find_points_in_match(match_name, team, auction)
    #   pool_team_ids = auction.teams.pluck(:id)
    #   MatchPoint.where(team:, match_name:)&.last&.total_points
    # end

    # def leader_of_match(match_name, auction)
    #   # joins(:team).where(match_name:, teams: { auction: }).order(total_points: :desc).team.user.username }
    # end
  end
end
