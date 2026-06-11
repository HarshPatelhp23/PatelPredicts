# frozen_string_literal: true

namespace :matches do
  task create_dummy_users: :environment do
    puts "=" * 50
    puts "Creating 9 Users with Teams"
    puts "=" * 50

    common_password = 'password'
    created_count = 0
    updated_count = 0
    error_count = 0

    9.times do |i|
      username = "Player-#{i + 1}"
      email = "player#{i + 1}@example.com"
      
      print "Processing #{username}... "
      
      begin
        existing_user = User.find_by(email: email)
        
        if existing_user
          # Update existing user
          existing_user.update!(otp_verified: true)
          
          # Check if team exists, create if not
          unless existing_user.teams.exists?
            Team.create!(
              team_name: existing_user.username,
              user_id: existing_user.id,
              total_purse: 1000000000,
              remaining_purse: 1000000000
            )
            puts "✓ UPDATED User & CREATED Team"
          else
            puts "✓ UPDATED User (Team already exists)"
          end
          
          updated_count += 1
        else
          # Create new user
          user = User.create!(
            username: username,
            email: email,
            password: common_password,
            password_confirmation: common_password,
            otp_verified: true
          )
          
          # Create associated team
          Team.create!(
            team_name: user.username,
            user_id: user.id,
            total_purse: 1000000000,
            remaining_purse: 1000000000
          )
          
          puts "✓ CREATED User & Team"
          created_count += 1
        end
      rescue ActiveRecord::RecordInvalid => e
        puts "✗ VALIDATION ERROR: #{e.message}"
        error_count += 1
      rescue => e
        puts "✗ ERROR: #{e.message}"
        error_count += 1
      end
    end

    puts "\n" + "=" * 50
    puts "SUMMARY"
    puts "=" * 50
    puts "Created: #{created_count} users with teams"
    puts "Updated: #{updated_count} users (teams checked/created)"
    puts "Errors:  #{error_count} users"
    puts "Total:   #{created_count + updated_count + error_count}/9 processed"
    puts "=" * 50
  end

  task insert_ipl_schedule: :environment do
    require Rails.root.join('lib/schedule')
    Schedule::IPL_SCHEDULE.each do |match|
      MatchSchedule.create!(
        match_number: match[:match_number],
        match_name: match[:match_name],
        stadium: match[:stadium],
        match_date: match[:date],
        time: match[:time]
      )
    end
    puts '++++++++++++++++++++++++++++++++++'
    puts '++++++++++++++++++++++++++++++++++'
    puts '++++++++++++++++++++++++++++++++++'
    puts '++++++++++++++++++++++++++++++++++'
    puts '+++++  DONE +++++++++++++++++'
    puts '++++++++++++++++++++++++++++++++++'
    puts '++++++++++++++++++++++++++++++++++'
    puts "TOTAL:- #{MatchSchedule.count} records inserted"
    puts "Today's match:- #{MatchSchedule.where(match_date: Date.current).pluck(:match_name)}"
  end

  task update_all_match_dates: :environment do
    Match.all.each do |m|
      match_date = m.send(:assign_match_date_and_auction)
      m.update_columns(match_date:)
    end
    puts '++++++++++++++++++++++++++++++++++'
    puts '++++++++++++++++++++++++++++++++++'
    puts '++++++++++++++++++++++++++++++++++'
    puts '++++++++++++++++++++++++++++++++++'
    puts '+++++  DONE +++++++++++++++++'
    puts '++++++++++++++++++++++++++++++++++'
    puts '++++++++++++++++++++++++++++++++++'
  end

   task update_all_match_points_dates: :environment do
    MatchPoint.all.each do |mp|
      match_date = Match.where(match_name: mp.match_name)&.last&.match_date
      mp.update_columns(match_date:)
    end
    puts "++++++++ DONE ++++++++++++++++++++++++++"
    puts "++++++++++ TOTAL UPDATED RECORD:- #{MatchPoint.where.not(match_date: nil).count}"
    puts "++++++++++ NOT UPDATED RECORD:- #{MatchPoint.where(match_date: nil).count}"
   end

  task insert_wc_schedule: :environment do
    require Rails.root.join('lib/schedule')
    
    MatchSchedule.destroy_all
    
    # Define team mappings inside the task
    TEAM_MAPPINGS = {
      'Afghanistan' => 'AFG',
      'Australia' => 'AUS',
      'Bangladesh' => 'BAN',
      'England' => 'ENG',
      'India' => 'IND',
      'New Zealand' => 'NZ',
      'Pakistan' => 'PAK',
      'South Africa' => 'SA',
      'Sri Lanka' => 'SL',
      'West Indies' => 'WI',
      'USA' => 'USA',
      'Canada' => 'CAN',
      'Ireland' => 'IRE',
      'Namibia' => 'NAM',
      'Nepal' => 'NEP',
      'Netherlands' => 'NED',
      'Zimbabwe' => 'ZIM',
      'Italy' => 'ITA',
      'Oman' => 'OMA',
      'Papua New Guinea' => 'PNG',
      'Scotland' => 'SCO',
      'Uganda' => 'UG',
      'Chennai Super Kings' => 'CSK',
      'Mumbai Indians' => 'MI',
      'Royal Challengers Bengaluru' => 'RCB',
      'Kolkata Knight Riders' => 'KKR',
      'Delhi Capitals' => 'DC',
      'Sunrisers Hyderabad' => 'SRH',
      'Rajasthan Royals' => 'RR',
      'Punjab Kings' => 'PBKS',
      'Lucknow Super Giants' => 'LSG',
      'Gujarat Titans' => 'GT'
    }.freeze
    
    Schedule::IPL_SCHEDULE.each do |match|
      # Convert full team names to short forms
      full_match_name = match[:match_name]
      
      # Split the match name to extract teams
      # Handle different match name formats:
      # 1. "Pakistan vs Netherlands"
      # 2. "Super 8s Y2 vs Y3" (for placeholder teams)
      # 3. "Semi-final 1: Winner A vs Winner B"
      
      # Check if it's a regular group stage match
      if full_match_name.include?(' vs ') && !full_match_name.include?('Super 8s') && !full_match_name.include?('Semi-final') && !full_match_name.include?('Final')
        # Split the match name
        teams = full_match_name.split(' vs ')
        team1 = teams[0].strip
        team2 = teams[1].strip
        
        # Convert to short forms using the mappings
        short_team1 = TEAM_MAPPINGS[team1] || team1  # Fallback to original if not found
        short_team2 = TEAM_MAPPINGS[team2] || team2  # Fallback to original if not found
        
        short_match_name = "#{short_team1} vs #{short_team2}"
      else
        # For Super 8s, Semi-finals, and Final matches, keep as is
        short_match_name = full_match_name
      end
      
      MatchSchedule.create!(
        match_number: match[:match_number],
        match_name: short_match_name,  # Use the converted short form
        stadium: match[:stadium],
        match_date: match[:date],
        time: match[:time]
      )
    end
    
    puts '++++++++++++++++++++++++++++++++++'
    puts '++++++++++++++++++++++++++++++++++'
    puts '++++++++++++++++++++++++++++++++++'
    puts '++++++++++++++++++++++++++++++++++'
    puts '+++++  DONE +++++++++++++++++'
    puts '++++++++++++++++++++++++++++++++++'
    puts '++++++++++++++++++++++++++++++++++'
    puts "TOTAL:- #{MatchSchedule.count} records inserted"
    puts "Today's match:- #{MatchSchedule.where(match_date: Date.current).pluck(:match_name)}"
  end

  task update_typo: :environment do
    MatchSchedule.find(35).update_columns(match_name: 'DC vs SRH')
  end

  task rushabh_team_update: :environment do
    updated_playing11 = WeeklyUserTeam.last.playing11 - [92]
    updated_playing11.push(71)

    updated_bench = WeeklyUserTeam.last.bench - [71]
    updated_bench.push(92)

    WeeklyUserTeam.last.update_columns(playing11: updated_playing11, bench: updated_bench)
  end

  task assign_last_week_team: :environment do
    user_ids = [1, 2, 3, 6, 9]
    user_ids.each do |id|
      user = User.find(id.to_i)
      last_week_team = user.weekly_user_teams.order(week_start_date: :desc).first
      user.weekly_user_teams.create(playing11: last_week_team.playing11, bench: last_week_team.bench,
                                    week_start_date: Date.new(2024, 5, 6),
                                    week_end_date: Date.new(2024, 5, 12))
    end
    # amit_mishra = Player.find(44)
    # mohit_sharma - Player.find(27)
    rushabh = User.find(2)
    updated_playing11 = rushabh.weekly_user_teams.order(week_start_date: :desc).first.playing11 - [44]
    updated_playing11.push(27)
    updated_bench = rushabh.weekly_user_teams.order(week_start_date: :desc).first.bench - [27]
    updated_bench.push(44)

    rushabh.weekly_user_teams.order(week_start_date: :desc).first.update_columns(playing11: updated_playing11,
                                                                                 bench: updated_bench)
    puts '+++++++++++++++++++++++++++++++++++'
    puts '+++++++++++++++++++++++++++++++++++'
    puts '+++++++++++++++++++++++++++++++++++'
    puts 'DONEEEEE'
  end

  task update_pbks_vs_rcb_match_point: :environment do
    Match.where(id: (1285..1307)).find_each do |match|
      match.update_columns(match_name: 'RCB vs PBKS')
    end

    puts 'DOOOOONE+++++++++++++++++++++++++'
    puts 'DOOOOONE+++++++++++++++++++++++++'
  end

  task update_weekly_team_record: :environment do
    kuki_team = WeeklyUserTeam.find(16)
    parth_team = WeeklyUserTeam.find(14)
  end

  task update_team_changes: :environment do
    w_teams_records = WeeklyUserTeam.where(week_end_date: Date.new(2025,4,20))
    w_teams_records.each do |record|
      playing11_changes  = WeeklyUserTeam.where(team: record.team, user: record.user, week: 4)&.first.playing11 - record.playing11
      bench_changes  = WeeklyUserTeam.where(team: record.team, user: record.user, week:4)&.first.bench - record.bench
      team_changes = {}
      team_changes[:playing11_changes] = playing11_changes
      team_changes[:bench_changes] = bench_changes
      record.update_columns(team_changes: team_changes)
    end
    puts "DOOOOONE ++++++++++++++++++++++++"
  end

  task update_week: :environment do
    first_week_teams = WeeklyUserTeam.where(id: (1..10))
    second_week_teams = WeeklyUserTeam.where(id: (14..23))
    first_week_teams.update_all(week: 1)
    second_week_teams.update_all(week: 2)
  end

  desc "Import IPL 2025 match schedules from series data"
  task import_schedules: :environment do
    series_data = SeriesMatchResponse.find(100).series_res

    match_records = []

    series_data["matchDetails"].each do |detail|
      next unless detail.key?("matchDetailsMap")

      match_details_map = detail["matchDetailsMap"]
      matches = match_details_map["match"] || []

      matches.each do |match|
        match_info = match["matchInfo"]
        next unless match_info

        match_name = "#{match_info['team1']['teamName']} vs #{match_info['team2']['teamName']}"
        match_date = Time.at(match_info['startDate'].to_i / 1000).to_date
        match_number = match_info['matchDesc'].gsub(/\D/, '')
        city = match_info['venueInfo']['city']
        stadium = match_info['venueInfo']['ground']
        match_records << {
          match_name: match_name,
          match_date: match_date,
          match_number: match_number.present? ? match_number.to_i : nil,
          city:,
          stadium:
        }
      end
    end

    # Create records in batches
    MatchSchedule.transaction do
      match_records.each do |record|
        MatchSchedule.find_or_create_by!(record)
      end
    end

    puts "Successfully imported #{match_records.size} match schedules"
  rescue StandardError => e
    puts "Error importing match schedules: #{e.message}"
    puts e.backtrace.join("\n")
  end

  desc "Import auction players from CSV"
  task import_players: :environment do
    require 'csv'

    file_path = Rails.root.join('lib', 'ImportData', 'auction_players.csv')
    
    CSV.foreach(file_path, headers: true) do |row|
      AuctionPlayer.create!(
        id: row['id'],
        name: row['name'],
        batting: row['batting'],
        bowling: row['bowling'],
        sold: row['sold'] == 'True',
        base_price: row['base_price'],
        # created_at: row['created_at'],
        # updated_at: row['updated_at'],
        note: row['note'] == 'NULL' ? nil : row['note']
      )
    end
    
    puts "Imported #{AuctionPlayer.count} players"
  end
end
