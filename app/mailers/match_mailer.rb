# app/mailers/match_mailer.rb
class MatchMailer < ApplicationMailer
  default to: "harshpatel.backend.dev@gmail.com"

  def match_summary(match)
    @match         = match
    @season        = match.season
    @winning_team  = match.winning_team
    @losing_team   = match.losing_team
    @sets          = match.match_sets.order(:id)
    subject = "Match Result: #{@winning_team&.name} beat #{@losing_team&.name} " \
              "(#{@match.winning_team_sets}-#{@match.losing_team_sets}) - #{@season&.name}"

    mail(subject: subject)
  end
end
