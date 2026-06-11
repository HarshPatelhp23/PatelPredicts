# frozen_string_literal: true

# rubocop:disable Metrics/MethodLength, Rails/HasManyOrHasOneDependent
class Player < ApplicationRecord
  include ApplicationHelper
  has_one_attached :image
  has_many :matches
  has_many :player_perfomace_points
  # has_and_belongs_to_many :teams
  has_many :players_teams, dependent: :destroy
  has_many :teams, through: :players_teams
  has_one :player_statistic, dependent: :destroy
  # belongs_to :team
  enum :role, %i[wicket_keeper batsman all_rounder bowler]
  # validates :base_price, presence: true

  def self.ransackable_attributes(auth_object = nil)
    super & %w[base_price created_at id name team_name foreigner updated_at bench points role]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[matches teams]
  end

  def self.sort_by_role(players)
    players.sort_by { |player| role_weights[player.role.to_sym] }
  end

  def owner(c_team)
    c_team.team_name
  end

  def format_indian_number(number)
    number = number.to_s.gsub(',', '').to_i
    crore = 0
    lakhs = 0

    if number >= 10_000_000
      crore = number / 10_000_000
      lakhs = (number % 10_000_000) / 100_000
    elsif number >= 100_000
      lakhs = number / 100_000
    end

    if crore.positive?
      if lakhs.positive?
        "#{crore} crore #{lakhs} lakhs"
      else
        "#{crore} crore"
      end
    elsif lakhs.positive?
      "#{lakhs} lakhs"
    else
      number.to_s
    end
  end

  def current_week_matches_count(week_matches, start_date, end_date)
    match_count = 0

    week_matches.each do |match|
      t1,t2 = match.match_name.split(' vs ')
      u_t1 = match_country_code[t1]&.upcase
      u_t2 = match_country_code[t2]&.upcase
      return if u_t1.blank? || u_t2.blank?

      match_count += 1 if (team_name.include?(u_t1) || team_name.include?(u_t2))
    end
    match_count
  end

  private

  def role_weights
    { wicket_keeper: 0, batsman: 1, all_rounder: 2, bowler: 3 }
  end
end
# rubocop:enable Metrics/MethodLength, Rails/HasManyOrHasOneDependent
