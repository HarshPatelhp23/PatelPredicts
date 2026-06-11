module Spl
  class RegistrationsController < Devise::RegistrationsController
    layout 'spl_auth'
    skip_before_action :verify_authenticity_token, only: [:send_otp, :verify_otp, :create]
    before_action :check_otp_verification, only: [:create]
    
    def new
      super
    end
    
    def send_otp
      email = params[:email]
      
      if Spl::User.exists?(email: email)
        render json: { success: false, message: "Email already registered" }, status: 422
      else
        OtpService.send_otp(email, params[:name])
        render json: { success: true, message: "OTP sent to your email" }
      end
    end
    
    def verify_otp
      email = params[:email]
      otp = params[:otp]
      
      if OtpService.verify_otp(email, otp)
        session[:otp_verified_email] = email
        session[:registration_data] = {
          name: params[:name],
          email: email,
          mobile_number: params[:mobile_number],
          category: params[:category]
        }
        render json: { success: true, message: "OTP verified successfully" }
      else
        render json: { success: false, message: "Invalid or expired OTP" }, status: 422
      end
    end
    
    def create
      # Ensure OTP is verified
      unless session[:otp_verified_email] == params[:spl_user][:email]
        render json: { 
          success: false, 
          message: "Please verify your email with OTP first",
          redirect_to: new_spl_user_registration_path
        }, status: 422 and return
      end
      
      # Build the resource
      build_resource(sign_up_params)
      
      # Save the user
      if resource.save
        # Clear sessions
        session.delete(:otp_verified_email)
        session.delete(:registration_data)
        
        # Sign in the user
        sign_in(resource_name, resource)
        
        render json: { 
          success: true, 
          message: "Account created successfully!",
          redirect_url: after_sign_up_path_for(resource)
        }
      else
        # Get error messages
        error_messages = resource.errors.full_messages.join(", ")
        
        render json: { 
          success: false, 
          message: error_messages,
          errors: resource.errors.full_messages
        }, status: 422
      end
    end
    
    protected
    
    def sign_up_params
      params.require(:spl_user).permit(:name, :email, :password, :password_confirmation, :mobile_number, :category)
    end
    
    def account_update_params
      params.require(:spl_user).permit(:name, :email, :password, :password_confirmation, :current_password, :mobile_number, :category, :team_name)
    end
    
    def check_otp_verification
      unless session[:otp_verified_email] == params[:spl_user][:email]
        flash[:alert] = "Please verify your email with OTP first"
        redirect_to new_spl_user_registration_path and return
      end
    end
    
    def after_sign_up_path_for(resource)
      spl_dashboard_path
    end
  end
end