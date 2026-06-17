# Preview all emails at http://localhost:3000/rails/mailers/match_mailer
class MatchMailerPreview < ActionMailer::Preview

  # Preview this email at http://localhost:3000/rails/mailers/match_mailer/match_summary
  def match_summary
    MatchMailer.match_summary
  end

end
