# frozen_string_literal: true

class UpdatePointsJob
  include Sidekiq::Job
  queue_as :default

  def perform
    begin
      ScoreFetcher.new.process_scorecard
    rescue => e
      Rails.logger.error "UpdatePointsJob failed: #{e.message}"
      raise # Re-raise to let Sidekiq handle retries
    end
  end
end
