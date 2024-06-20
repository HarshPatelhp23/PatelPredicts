# frozen_string_literal: true

namespace :matches do
  task insert_ipl_schedule: :environment do
    require Rails.root.join('lib/match_schedule')
    IPL_SCHEDULE.each do |match|
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

  task insert_wc_scehdule: :environment do
    require Rails.root.join('lib/match_schedule')
    MatchSchedule.destroy_all
    T20_WORLDCUP_SCHEDULE.each do |match|
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
    weekly_user_team = WeeklyUserTeam.find(46)
    weekly_user_team.update_columns(week_start_date: Date.new(2024, 6, 17), week_end_date: Date.new(2024, 6, 20))
    puts '++++++++++++++++++++++++++++++++++++++++'
    puts '++++++++++++++++++++++++++++++++++++++++'
    puts '++++++++++++++++++++++++++++++++++++++++'
    puts '++++++++++++++++++++++++++++++++++++++++'
    puts '++++++++++++++++ DONE  ++++++++++++++++++++++'
    puts '++++++++++++++++++++++++++++++++++++++++'
    puts '++++++++++++++++++++++++++++++++++++++++'
    puts '++++++++++++++++++++++++++++++++++++++++'
    puts '++++++++++++++++++++++++++++++++++++++++'
  end
end
