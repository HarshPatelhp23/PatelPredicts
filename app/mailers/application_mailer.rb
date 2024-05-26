# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: 'noreply.patelpredicts@gmail.com'
  layout 'mailer'
end
