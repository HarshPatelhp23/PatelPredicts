class OtpService

  def self.generate_otp
    rand(100000..999999).to_s
  end
  
  def self.send_otp(email, username)
    otp_code = generate_otp
    otp_record = SplOtp.find_or_initialize_by(email:)
    otp_record.update(
      otp_code:,
      otp_sent_at: Time.current,
      verified: false
    )
    # In production, integrate with SMS/Email service
    # For now, we'll log it and return
    Rails.logger.info "OTP for #{email}: #{otp_code}"
    
    WelcomeMailer.with(otp: otp_code, username:, email:).verify_otp.deliver_now
    
    otp_record
  end
  
  def self.verify_otp(email, otp_code)
    otp_record = SplOtp.find_by(email: email, otp_code: otp_code)
    
    if otp_record && otp_record.otp_sent_at > 10.minutes.ago
      otp_record.update(verified: true)
      return true
    end
    false
  end
  
  def self.otp_verified?(email)
    otp_record = SplOtp.find_by(email:)
    otp_record&.verified && otp_record.otp_sent_at > 10.minutes.ago
  end
end
