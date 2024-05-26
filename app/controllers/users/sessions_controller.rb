# frozen_string_literal: true

module Users
  class SessionsController < Devise::SessionsController
    def create
      user = User.find_by(email: params[:user][:email])
      if user.blank?
        redirect_to user_session_path, alert: 'Invalid Email or Password'
        return
      end

      if user.otp_verified?
        super
      else
        redirect_to verify_otp_path(user.id), alert: 'Your OTP verification is pending please complete it'
      end
    end
  end
end
