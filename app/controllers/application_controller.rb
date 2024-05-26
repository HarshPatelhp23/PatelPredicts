# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Pagy::Backend
  protect_from_forgery with: :null_session
  before_action :configure_permitted_parameters, if: :devise_controller?

  def after_sign_in_path_for(resource)
    resource.instance_of?(User) ? '/after_login' : '/admin'
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: %i[email passowrd password_confirmation username])
    devise_parameter_sanitizer.permit(:account_update, keys: %i[email passowrd password_confirmation username])
  end
end
