# frozen_string_literal: true

require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module LiveAuction
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0
    config.assets.enabled = true
    config.time_zone = 'Kolkata'
    config.active_job.queue_adapter = :sidekiq
    config.autoload_paths += %W(#{config.root}/lib)
    Rails.application.config.assets.paths << Rails.root.join('app', 'assets', 'javascripts')
    Rails.application.config.assets.precompile += %w( application.js channels/* )


    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
  end
end
