class WeeklyReportMailer < ApplicationMailer
  def weekly_team_report(user, week_start, week_end, team_pdf_path, schedule_pdf_path)
    @user = user
    @week_start = week_start
    @week_end = week_end
    @team = user.teams.first

    # Attach the PDFs
    attachments["Teams.pdf"] = File.read(team_pdf_path)
    attachments["Weekly_Schedule.pdf"] = File.read(schedule_pdf_path)

    mail(
      to: user.email,
      subject: "Patel-Predicts Weekly Report - #{week_start.strftime('%d %b')} to #{week_end.strftime('%d %b, %Y')}"
    )
  end
end