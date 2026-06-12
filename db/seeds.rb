# frozen_string_literal: true

AdminUser.create!(
	email: ENV['ADMIN_EMAIL'] || Rails.application.credentials.dig(:admin_user, :email), 
	password: ENV['ADMIN_PASSWORD'] || Rails.application.credentials.dig(:admin_user, :password), 
	password_confirmation: ENV['ADMIN_PASSWORD'] || Rails.application.credentials.dig(:admin_user, :password)
)