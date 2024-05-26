# frozen_string_literal: true

class WelcomeMailer < ApplicationMailer

  def verify_otp
    @username = params[:username]
    @otp = params[:otp]
    mail(
      from: 'noreply.patelpredicts@gmail.com',
      to: params[:email],
      subject: 'Confirm Your Account'
    )
  end

  def resend_otp
    @username = params[:username]
    @otp = params[:otp]
    mail(
      from: 'noreply.patelpredicts@gmail.com',
      to: params[:email],
      subject: 'Patel-Predicts OTP: Resend Request"'
    )
  end
end
