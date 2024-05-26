# frozen_string_literal: true

module Users
  class RegistrationsController < Devise::RegistrationsController
    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Layout/LineLength
    def create
      otp = rand(100_000..999_999)
      @user = User.new(email: params[:user][:email], username: params[:user][:username],
                       password: params[:user][:password], password_confirmation: params[:user][:password_confirmation], otp:)
      WelcomeMailer.with(otp:, username: params[:user][:username],
                         email: params[:user][:email]).verify_otp.deliver_now
      if @user.save
        Team.create(team_name: @user.username, user_id: @user.id)
        redirect_to verify_otp_path(@user)
        flash[:notice] = 'We have sent otp to your email please confirm it'
      else
        redirect_to root_path
        flash[:alert] = @user.errors.full_messages.first
      end
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength, Layout/LineLength
  end
end
