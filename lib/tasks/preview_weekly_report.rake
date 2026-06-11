# lib/tasks/preview_weekly_report.rake
# Rake task to preview/test the weekly report PDFs

namespace :weekly_report do
  desc "Generate preview PDFs for the current week"
  task preview: :environment do
    week_start = Date.today.beginning_of_week(:monday)
    week_end = week_start + 6.days

    puts "Generating preview PDFs for week: #{week_start} to #{week_end}"
    
    # Generate Team Roster PDF
    puts "\n1. Generating Team Roster PDF..."
    team_pdf_generator = WeeklyTeamReportPdf.new(week_start, week_end)
    team_pdf_content = team_pdf_generator.generate
    
    team_pdf_path = Rails.root.join('tmp', "preview_team_roster_#{week_start.strftime('%Y%m%d')}.pdf")
    File.open(team_pdf_path, 'wb') { |f| f.write(team_pdf_content) }
    puts "   ✓ Saved to: #{team_pdf_path}"

    # Generate Schedule PDF
    puts "\n2. Generating Weekly Schedule PDF..."
    schedule_pdf_generator = WeeklySchedulePdf.new(week_start, week_end)
    schedule_pdf_content = schedule_pdf_generator.generate
    
    schedule_pdf_path = Rails.root.join('tmp', "preview_schedule_#{week_start.strftime('%Y%m%d')}.pdf")
    File.open(schedule_pdf_path, 'wb') { |f| f.write(schedule_pdf_content) }
    puts "   ✓ Saved to: #{schedule_pdf_path}"

    puts "\n✅ Preview PDFs generated successfully!"
    puts "\nFile locations:"
    puts "  - #{team_pdf_path}"
    puts "  - #{schedule_pdf_path}"
  end

  desc "Send test email to a specific user"
  task :test_email, [:email] => :environment do |t, args|
    if args[:email].blank?
      puts "Usage: rake weekly_report:test_email[user@example.com]"
      exit
    end

    user = User.find_by(email: args[:email])
    
    unless user
      puts "❌ User not found with email: #{args[:email]}"
      exit
    end

    week_start = Date.today.beginning_of_week(:monday)
    week_end = week_start + 6.days

    puts "Generating PDFs and sending test email to: #{user.email}"
    
    # Generate PDFs
    team_pdf = WeeklyTeamReportPdf.new(week_start, week_end).generate
    schedule_pdf = WeeklySchedulePdf.new(week_start, week_end).generate
    
    team_path = Rails.root.join('tmp', 'test_team.pdf')
    schedule_path = Rails.root.join('tmp', 'test_schedule.pdf')
    
    File.open(team_path, 'wb') { |f| f.write(team_pdf) }
    File.open(schedule_path, 'wb') { |f| f.write(schedule_pdf) }
    
    # Send email
    WeeklyReportMailer.weekly_team_report(
      user,
      week_start,
      week_end,
      team_path,
      schedule_path
    ).deliver_now
    
    puts "✅ Test email sent successfully to #{user.email}"
    
    # Cleanup
    File.delete(team_path) if File.exist?(team_path)
    File.delete(schedule_path) if File.exist?(schedule_path)
  end

  desc "Send weekly reports to all users via email"
  task send_to_all: :environment do
    week_start = Date.today.beginning_of_week(:monday)
    week_end = week_start + 6.days

    puts "\n📧 Sending Weekly Reports to All Users"
    puts "=" * 50
    puts "Week: #{week_start.strftime('%d %b %Y')} to #{week_end.strftime('%d %b %Y')}"
    puts "=" * 50

    # Get all users with valid emails
    users = User.where.not(email: nil).where.not(email: '')
    
    if users.empty?
      puts "\n❌ No users found with valid email addresses"
      exit
    end

    puts "\nFound #{users.count} user(s) with valid emails"
    
    # Generate PDFs once (same for all users)
    puts "\nGenerating PDFs..."
    team_pdf = WeeklyTeamReportPdf.new(week_start, week_end).generate
    schedule_pdf = WeeklySchedulePdf.new(week_start, week_end).generate
    
    team_path = Rails.root.join('tmp', 'weekly_team.pdf')
    schedule_path = Rails.root.join('tmp', 'weekly_schedule.pdf')
    
    File.open(team_path, 'wb') { |f| f.write(team_pdf) }
    File.open(schedule_path, 'wb') { |f| f.write(schedule_pdf) }
    puts "✓ PDFs generated successfully"

    # Send emails to each user
    puts "\nSending emails..."
    sent_count = 0
    failed_count = 0
    
    users.each_with_index do |user, index|
      begin
        WeeklyReportMailer.weekly_team_report(
          user,
          week_start,
          week_end,
          team_path,
          schedule_path
        ).deliver_now
        
        sent_count += 1
        puts "  #{index + 1}/#{users.count} ✓ Sent to: #{user.email} (#{user.username})"
        
        # Small delay to avoid overwhelming mail server
        sleep(0.5) if users.count > 10
        
      rescue => e
        failed_count += 1
        puts "  #{index + 1}/#{users.count} ✗ Failed for: #{user.email} - #{e.message}"
      end
    end
    
    # Cleanup temp files
    File.delete(team_path) if File.exist?(team_path)
    File.delete(schedule_path) if File.exist?(schedule_path)
    
    puts "\n" + "=" * 50
    puts "📊 Summary:"
    puts "  ✓ Successfully sent: #{sent_count}"
    puts "  ✗ Failed: #{failed_count}" if failed_count > 0
    puts "=" * 50
    puts "\n✅ Email sending completed!"
  end

  desc "Send weekly reports to specific users (comma-separated emails)"
  task :send_to, [:emails] => :environment do |t, args|
    if args[:emails].blank?
      puts "Usage: rake weekly_report:send_to[email1@example.com,email2@example.com]"
      exit
    end

    week_start = Date.today.beginning_of_week(:monday)
    week_end = week_start + 6.days
    
    email_list = args[:emails].split(',').map(&:strip)
    
    puts "\n📧 Sending Weekly Reports to Specific Users"
    puts "=" * 50
    puts "Week: #{week_start.strftime('%d %b %Y')} to #{week_end.strftime('%d %b %Y')}"
    puts "Target emails: #{email_list.join(', ')}"
    puts "=" * 50

    # Generate PDFs
    puts "\nGenerating PDFs..."
    team_pdf = WeeklyTeamReportPdf.new(week_start, week_end).generate
    schedule_pdf = WeeklySchedulePdf.new(week_start, week_end).generate
    
    team_path = Rails.root.join('tmp', 'weekly_team.pdf')
    schedule_path = Rails.root.join('tmp', 'weekly_schedule.pdf')
    
    File.open(team_path, 'wb') { |f| f.write(team_pdf) }
    File.open(schedule_path, 'wb') { |f| f.write(schedule_pdf) }
    puts "✓ PDFs generated successfully"

    # Send emails
    puts "\nSending emails..."
    sent_count = 0
    failed_count = 0
    
    email_list.each_with_index do |email, index|
      user = User.find_by(email: email)
      
      if user.nil?
        puts "  #{index + 1}/#{email_list.count} ✗ User not found: #{email}"
        failed_count += 1
        next
      end
      
      begin
        WeeklyReportMailer.weekly_team_report(
          user,
          week_start,
          week_end,
          team_path,
          schedule_path
        ).deliver_now
        
        sent_count += 1
        puts "  #{index + 1}/#{email_list.count} ✓ Sent to: #{email} (#{user.username})"
        
      rescue => e
        failed_count += 1
        puts "  #{index + 1}/#{email_list.count} ✗ Failed for: #{email} - #{e.message}"
      end
    end
    
    # Cleanup
    File.delete(team_path) if File.exist?(team_path)
    File.delete(schedule_path) if File.exist?(schedule_path)
    
    puts "\n" + "=" * 50
    puts "📊 Summary:"
    puts "  ✓ Successfully sent: #{sent_count}"
    puts "  ✗ Failed: #{failed_count}" if failed_count > 0
    puts "=" * 50
    puts "\n✅ Email sending completed!"
  end

  desc "Manually run the weekly report job"
  task run: :environment do
    puts "Running Weekly Report Job manually..."
    puts "=" * 50
    
    WeeklyReportWorker.new.perform
    
    puts "=" * 50
    puts "✅ Weekly Report Job completed!"
  end

  desc "Show statistics about the current week's data"
  task stats: :environment do
    week_start = Date.today.beginning_of_week(:monday)
    week_end = week_start + 6.days

    puts "\n📊 Weekly Report Statistics"
    puts "=" * 50
    puts "Week: #{week_start.strftime('%d %b %Y')} to #{week_end.strftime('%d %b %Y')}"
    puts "=" * 50
    
    # Users
    total_users = User.count
    users_with_email = User.where.not(email: nil).where.not(email: '').count
    users_with_teams = User.joins(:team).distinct.count
    
    puts "\nUsers:"
    puts "  Total users: #{total_users}"
    puts "  Users with valid email: #{users_with_email}"
    puts "  Users with teams: #{users_with_teams}"
    
    # Matches
    matches = MatchSchedule.where(match_date: week_start..week_end)
    
    puts "\nMatches:"
    puts "  Total matches this week: #{matches.count}"
    
    if matches.any?
      matches.each do |match|
        puts "  - Match #{match.match_number}: #{match.match_name} (#{match.match_date.strftime('%a, %d %b')})"
      end
    else
      puts "  No matches scheduled for this week"
    end
    
    # Players
    total_players = Player.count
    playing11 = Player.where(bench: false).count
    bench = Player.where(bench: true).count
    
    puts "\nPlayers:"
    puts "  Total players: #{total_players}"
    puts "  In Playing 11: #{playing11}"
    puts "  On Bench: #{bench}"
    
    puts "\n" + "=" * 50
  end

  desc "List all scheduled Sidekiq cron jobs"
  task jobs: :environment do
    puts "\n📅 Scheduled Sidekiq Cron Jobs"
    puts "=" * 50
    
    Sidekiq::Cron::Job.all.each do |job|
      puts "\nJob Name: #{job.name}"
      puts "  Class: #{job.klass}"
      puts "  Cron: #{job.cron}"
      puts "  Queue: #{job.queue}"
      puts "  Description: #{job.description}"
      puts "  Last Run: #{job.last_enqueue_time || 'Never'}"
      puts "  Next Run: #{job.next_enqueue_time}"
      puts "  Status: #{job.status}"
    end
    
    puts "\n" + "=" * 50
  end
end
