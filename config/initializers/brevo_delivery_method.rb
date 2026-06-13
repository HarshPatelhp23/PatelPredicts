# config/initializers/brevo_delivery_method.rb
class BrevoDeliveryMethod
  attr_accessor :settings

  def initialize(settings = {})
    @settings = settings
  end

  def deliver!(mail)
    api_instance = Brevo::TransactionalEmailsApi.new
    
    # Extract sender information
    sender_email = mail.from.first
    sender_name = mail[:from].display_names.first || "PatelPredicts"
    recipient_email = mail.to.first
    subject = mail.subject || "No Subject"
    
    # Extract content correctly
    html_content = nil
    text_content = nil
    
    if mail.multipart?
      if mail.html_part
        html_content = mail.html_part.body.decoded
      end
      if mail.text_part
        text_content = mail.text_part.body.decoded
      end
    else
      # Single part email
      body = mail.body.decoded
      if mail.content_type&.include?('text/html')
        html_content = body
        text_content = ActionView::Base.full_sanitizer.sanitize(body)
      else
        text_content = body
        html_content = "<p>#{body.gsub(/\n/, '<br>')}</p>"
      end
    end
    
    # Ensure we have content
    html_content = " " if html_content.blank?
    text_content = " " if text_content.blank?


    # Create the email object with explicit content
    send_smtp_email = Brevo::SendSmtpEmail.new
    send_smtp_email.sender = { email: sender_email, name: sender_name }
    send_smtp_email.to = [{ email: recipient_email, name: recipient_email.split('@').first }]
    send_smtp_email.subject = subject
    send_smtp_email.html_content = html_content
    send_smtp_email.text_content = text_content
    send_smtp_email.reply_to = { email: sender_email, name: sender_name }

    # Send via Brevo API
    begin
      result = api_instance.send_transac_email(send_smtp_email)
      Rails.logger.info "✅ Email sent via Brevo to #{recipient_email}, Message ID: #{result.message_id}"
      result
    rescue => e
      Rails.logger.error "❌ Brevo email failed: #{e.message}"
      if e.respond_to?(:response_body)
        Rails.logger.error "Response body: #{e.response_body}"
      end
      raise e
    end
  end
end

# Register the delivery method
ActionMailer::Base.add_delivery_method :brevo, BrevoDeliveryMethod
ActionMailer::Base.add_delivery_method :brevo, BrevoDeliveryMethod
