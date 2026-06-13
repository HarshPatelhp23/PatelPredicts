# config/initializers/brevo.rb
require 'brevo'

# Get API key from credentials
api_key = ENV['BREVO_API_KEY']|| Rails.application.credentials.dig(:brevo, :api_key)

if api_key.blank?
  Rails.logger.warn "⚠️ Brevo API key not found in credentials"
else
  # Configure Brevo globally
  Brevo.configure do |config|
    config.api_key['api-key'] = api_key
    config.api_key['partner-key'] = api_key
  end
  
  Rails.logger.info "✅ Brevo configured with API key"
end
