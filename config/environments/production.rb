require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.cache_classes = true
  config.eager_load = true
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true

  # CRITICAL CHANGE: Enable on-the-fly compilation
  config.assets.compile = true  # Changed from false to true

  # Enable static file serving
  config.public_file_server.enabled = ENV["RAILS_SERVE_STATIC_FILES"].present?
  config.public_file_server.enabled = true  # Force this for Render

  # Action Cable Configuration
  config.action_cable.mount_path = '/cable'
  config.action_cable.url = "wss://patelpredicts-4mw4.onrender.com/cable"
  config.action_cable.allowed_request_origins = [
    'https://patelpredicts-4mw4.onrender.com',
    'https://www.patelpredicts-4mw4.onrender.com'
  ]
  config.action_cable.disable_request_forgery_protection = true

  # Other settings remain the same...
  config.log_level = :info
  config.log_tags = [ :request_id ]
  config.action_mailer.perform_caching = false
  config.i18n.fallbacks = true
  config.active_support.report_deprecations = false
  config.log_formatter = ::Logger::Formatter.new

  if ENV['RAILS_LOG_TO_STDOUT'].present?
    logger = ActiveSupport::Logger.new($stdout)
    logger.formatter = config.log_formatter
    config.logger = ActiveSupport::TaggedLogging.new(logger)
  end

  config.action_mailer.delivery_method = :brevo
  config.action_mailer.default_url_options = { 
    host: 'patelpredicts-4mw4.onrender.com',
    protocol: 'https'
  }
  config.action_mailer.asset_host = 'https://patelpredicts-4mw4.onrender.com'
  config.action_mailer.perform_deliveries = true
  config.action_mailer.raise_delivery_errors = true

  config.active_record.dump_schema_after_migration = false
end
