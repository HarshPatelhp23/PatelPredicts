# frozen_string_literal: true

AdminUser.create!(email: Rails.application.credentials.dig(:admin_user, :email), password: Rails.application.credentials.dig(:admin_user, :password), password_confirmation: Rails.application.credentials.dig(:admin_user, :password))