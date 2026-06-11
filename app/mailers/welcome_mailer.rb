# frozen_string_literal: true

class WelcomeMailer < ApplicationMailer
  def verify_otp
    @username = params[:username]
    @otp = params[:otp]
    mail(
      from: email_address_with_name("noreplyypatelpredicts@gmail.com", "PatelPredicts"),
      to: params[:email],
      subject: 'Welcome To Patel-Predicts'
    )
  end

  def resend_otp
    @username = params[:username]
    @otp = params[:otp]
    mail(
      from: email_address_with_name("noreplyypatelpredicts@gmail.com", "PatelPredicts"),
      to: params[:email],
      subject: 'Patel-Predicts OTP: Resend Request"'
    )
  end
end
