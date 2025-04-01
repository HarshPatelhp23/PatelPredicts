# frozen_string_literal: true

require 'sidekiq'
require 'sidekiq-cron'

# config/initializers/sidekiq.rb
require 'sidekiq'
require 'sidekiq-cron'

# Sidekiq.configure_server do |config|
#   config.on(:startup) do
#     cron_file = Rails.root.join('config', 'sidekiq_cron.yml')
    
#     if File.exist?(cron_file)
#       Sidekiq::Cron::Job.load_from_hash(YAML.load_file(cron_file))
#     else
#       Rails.logger.error("⚠️ sidekiq_cron.yml not found at #{cron_file}")
#     end
#   end
# end

# Sidekiq.configure_client do |config|
#   config.redis = { url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/1') }
# end

# schedule_file = 'config/sidekiq_cron.yml'

# Sidekiq::Cron::Job.load_from_hash YAML.load_file(schedule_file) if File.exist?(schedule_file) && Sidekiq.server?




Sidekiq.configure_server do |config|
  config.redis = { url: 'redis://localhost:6379/1' }
  
  schedule_file = "config/schedule.yml"
  if File.exist?(schedule_file)
    Sidekiq::Cron::Job.load_from_hash(YAML.load_file(schedule_file))
  end
end

Sidekiq.configure_client do |config|
  config.redis = { url: 'redis://localhost:6379/1' }
end