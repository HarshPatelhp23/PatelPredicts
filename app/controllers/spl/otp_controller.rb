module Spl
  class OtpController < ApplicationController
    skip_before_action :verify_authenticity_token
    
    def send_otp
      email = params[:email]
      
      if email.present?
        OtpService.send_otp(email)
        render json: { success: true, message: "OTP sent successfully" }
      else
        render json: { success: false, message: "Email is required" }, status: 422
      end
    end
    
    def verify_otp
      email = params[:email]
      otp = params[:otp]
      
      if OtpService.verify_otp(email, otp)
        render json: { success: true, message: "OTP verified successfully" }
      else
        render json: { success: false, message: "Invalid OTP" }, status: 422
      end
    end
  end
end
