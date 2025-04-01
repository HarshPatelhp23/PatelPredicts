# frozen_string_literal: true

namespace :matches do
  task insert_ipl_schedule: :environment do
    require Rails.root.join('lib/schedule')
    Schedule::IPL_SCHEDULE.each do |match|
      MatchSchedule.create!(
        match_number: match[:match_number],
        match_name: match[:match_name],
        stadium: match[:stadium],
        match_date: match[:date]
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

  task insert_wc_scehdule: :environment do
    require Rails.root.join('lib/schedule')
    MatchSchedule.destroy_all
    CT_2025_SCHEDULE.each do |match|
      MatchSchedule.create!(
        match_number: match[:match_number],
        match_name: match[:match_name],
        stadium: match[:stadium],
        match_date: match[:match_date],
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
    w_teams_records = WeeklyUserTeam.where(week_end_date: Date.new(2025,4,6))
    w_teams_records.each do |record|
      playing11_changes  = WeeklyUserTeam.where(team: record.team, user: record.user, week: 2)&.first.playing11 - record.playing11
      bench_changes  = WeeklyUserTeam.where(team: record.team, user: record.user, week:2)&.first.bench - record.bench
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
    series_data = SeriesMatchResponse.where.not(series_res: '{}')&.last.series_res

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
        match_number = match_info['matchDesc'].gsub(/\D/, '') # Extract numbers from matchDesc

        match_records << {
          match_name: match_name,
          match_date: match_date,
          match_number: match_number.present? ? match_number.to_i : nil
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
end
