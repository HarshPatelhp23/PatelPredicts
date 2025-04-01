# frozen_string_literal: true

class Match < ApplicationRecord
  include ApplicationHelper
  has_many :player_perfomace_points
  belongs_to :player, optional: true
  belongs_to :auction, optional: true
  belongs_to :team
  before_create :assign_match_date_and_auction
  # after_save :calculate_grand_total
  # after_save :calculate_one_match_point
  # after_save :update_player_point
  # after_save :final_total_user_points

  def self.ransackable_attributes(_auth_object = nil)
    %w[created_at id match_name player_id points updated_at team_id auction_id player_perfomace_points_id]
  end

  def self.ransackable_associations(_auth_object = nil)
    []
  end

  def self.find_top_picks(match_name)
    where(match_name:).order(points: :desc).limit(5).pluck(:player_id)
  end

  def self.find_best_batsman(match_name)
    joins(:player).where(player: { role: 'batsman' })
    where(match_name:).order(points: :desc).first&.player
  end

  def self.find_best_bowler(match)
    joins(:player).where(player: { role: 'bowler' }).where(match_name: match).order(points: :desc).first&.player
  end

  # def calculate_grand_total
  #   points = team.matches.pluck(:points)
  #   grand_total = points.sum
  #   team.user.update(grand_total:)
  # end

  def calculate_one_match_point
    match_point = MatchPoint.find_or_create_by(match_name:, team_id: team.id)
    total_points = team&.matches&.where(match_name:)&.pluck(:points).sum
    match_point.update(total_points:)
    # match_point.team.update(grand_total: points)
  end

  # def update_player_point
  #   return if same_match_for_different_team

  #   points=  0 if points.nil?
  #   total_points = points + (player.players_teams.where(team:)&.first&.points || 0)
  #   PlayersTeam.where(player_id:, team_id:)&.first&.update(points: total_points)
  #   team.update(grand_total: total_points)
  # end

  # def final_total_user_points
  #   final_total_points = team.user.calculate_final_total_points
  #   team.user.update(final_total_points:)
  # end

  private

  def assign_match_date_and_auction
    self.match_date = set_match_details(match_name)[:match_date]
    self.auction = team.auction
  end

  def same_match_for_different_team
    self.class.where(player:, match_name:, match_date:).exists?
  end
end
