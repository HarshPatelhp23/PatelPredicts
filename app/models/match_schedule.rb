# frozen_string_literal: true

class MatchSchedule < ApplicationRecord
  scope :ipl_match_today, -> { where(match_date: Date.current) }
  # scope :ipl_match_today, -> { where(match_date: Date.current + 1.days) }

  class << self
    def fetch_ipl_teams_for_today
      ipl_match_today.map { |match| match.match_name.split(' vs ') }
    end
  end
end
