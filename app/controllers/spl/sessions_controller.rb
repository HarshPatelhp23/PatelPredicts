module Spl
  class SessionsController < Devise::SessionsController
    layout 'spl_auth'
    skip_before_action :verify_authenticity_token, only: [:send_otp_login, :verify_otp_login]
    skip_before_action :require_no_authentication, only: [:create]

    def new
      super
    end
    
    # def create
    #   self.resource = warden.authenticate!(auth_options)
    #   set_flash_message!(:notice, :signed_in)
    #   sign_in(resource_name, resource)
    #   yield resource if block_given?
    #   respond_with resource, location: after_sign_in_path_for(resource)
    # end

     def create
      # First, sign out any existing session
      sign_out(resource_name) if current_spl_user
      
      # Authenticate the user
      self.resource = warden.authenticate!(auth_options)
      
      if resource.otp_verified?
        # Sign in the user
        sign_in(resource_name, resource)
        
        # Set flash message
        flash[:notice] = 'Welcome to Patel-Predicts'
        
        # Handle response based on format
        respond_to do |format|
          format.html { redirect_to after_sign_in_path_for(resource) }
          format.json { 
            render json: {
              success: true,
              message: 'Welcome to Patel-Predicts',
              redirect_url: after_sign_in_path_for(resource)
            }
          }
        end
      else
        # OTP not verified
        warden.logout(resource_name)
        
        respond_to do |format|
          format.html { 
            redirect_to new_spl_user_session_path, 
            alert: 'Verification Pending! Please verify your email first.'
          }
          format.json {
            render json: { 
              success: false, 
              message: 'Verification Pending!' 
            }, status: :unauthorized
          }
        end
      end
    rescue Warden::NotAuthenticated => e
      respond_to do |format|
        format.html {
          flash[:alert] = 'Invalid email or password'
          redirect_to new_spl_user_session_path
        }
        format.json {
          render json: { success: false, message: 'Invalid email or password' }, 
          status: :unauthorized
        }
      end
    end
    
    def otp_login
      render :otp_login
    end
    
    def send_otp_login
      email = params[:email]
      user = Spl::User.find_by(email: email)
      
      if user
        OtpService.send_otp(email, user.name)
        render json: { success: true, message: "OTP sent to your email" }
      else
        render json: { success: false, message: "Email not found" }, status: 404
      end
    end
    
    def verify_otp_login
      email = params[:email]
      otp = params[:otp]
      
      if OtpService.verify_otp(email, otp)
        user = Spl::User.find_by(email: email)
        sign_in(resource_name, user)
        render json: { success: true, redirect_url: after_sign_in_path_for(user) }
      else
        render json: { success: false, message: "Invalid or expired OTP" }, status: 422
      end
    end
    
    protected
    
    # This is the critical method for sign in redirect
    def after_sign_in_path_for(resource)
      spl_dashboard_path
    end
    
    def after_sign_out_path_for(resource_or_scope)
      new_spl_user_session_path
    end
  end
end
