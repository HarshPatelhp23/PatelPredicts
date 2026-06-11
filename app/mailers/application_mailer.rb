# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  helper :application
  # default from: 'harsh.patel@corelto.com'
  default from: email_address_with_name("noreplyypatelpredicts@gmail.com", "PatelPredicts")
  # default from: 'noreply.patelpredicts@gmail.com'
  layout 'mailer'
end
