# frozen_string_literal: true

namespace :players do
  desc 'TODO'
  task update_points: :environment do
    Player.where(points: 0).find_each(batch_size: 100) do |player|
      points = Match.where(player:).pluck(:points)&.sum
      player.update_columns(points:)
      puts "Player - #{player.name} updated successfully"
    end
  end
  puts 'Done!'

  task update_weekly_user_teams: :environment do
    User.find_each do |user|
      playing11 = user.team.players.where(bench: true).pluck(:id)
      bench = user.team.players.where(bench: false).pluck(:id)

      user.weekly_user_teams.create(week_start_date: Date.new(204, 2, 26), week_end_date: Date.new(2024, 3, 3),
                                    playing11:, bench:)
    end
    puts 'Done!'
  end

  task update_slugs: :environment do
    User.find_each(&:save)
    Team.find_each(&:save)
    puts '++++++++++++++++++++++++++++++++++++++++++++'
    puts '++++++++++++++++++++++++++++++++++++++++++++'
    puts '++++++++++++++++++++++++++++++++++++++++++++'
    puts '++++++++++++++++++++++++++++++++++++++++++++'
    puts '++++++++++++++++++++++++++++++++++++++++++++'
    puts '++++++++++++++++++++++++++++++++++++++++++++'
    puts '++++++++++++++++++++++++++++++++++++++++++++'
    puts "Total Updated User Record:-#{User.where.not(slug: nil).count}"
    puts "Total Updated Team Records:-#{Team.where.not(slug: nil).count}"
    puts '++++++++++++++++++++++++++++++++++++++++++++'
    puts '++++++++++++++++++++++++++++++++++++++++++++'
    puts '++++++++++++++++++++++++++++++++++++++++++++'
    puts '++++++++++++++++++++++++++++++++++++++++++++'
    puts '++++++++++++++++++++++++++++++++++++++++++++'
    puts '++++++++++++++++++++++++++++++++++++++++++++'
    puts '++++++++++++++++++++++++++++++++++++++++++++'
  end

  task recorrect_user_weekly_teams: :environment do
    WeeklyUserTeam.update_all(week_end_date: Date.parse('2024-03-24'))
    puts '++++++++++++++++++++++++++++++++++++'
    puts '++++++++++++++++++++++++++++++++++++'
    puts '++++++++++++++++++++++++++++++++++++'
    puts '++++++++++++++++++++++++++++++++++++'
    puts '++++++++++++++++++++++++++++++++++++'
    puts '++++++++++++++++++++++++++++++++++++'
    puts "Total updated Records:- #{WeeklyUserTeam.where(week_end_date: Date.parse('2024-03-24')).count}"
    User.find_each do |u|
      next if u.weekly_user_teams.blank?

      puts '++++++++++++++++++++++++++++'
      puts '++++++++++++++++++++++++++++'
      puts '++++++++++++++++++++++++++++'
      puts '++++++++++++++++++++++++++++'
      puts '++++++++++++++++++++++++++++'
      puts '++++++++++++++++++++++++++++'
      puts "#{u.username}:- #{u.weekly_user_teams.first.week_end_date}"
      puts '++++++++++++++++++++++++++++'
      puts '++++++++++++++++++++++++++++'
      puts '++++++++++++++++++++++++++++'
      puts '++++++++++++++++++++++++++++'
      puts '++++++++++++++++++++++++++++'
      puts '++++++++++++++++++++++++++++'
    end
  end

  task reupdate_rushabh_team: :environment do
    rushabh = User.find(2)
    this_week_team = rushabh.weekly_user_teams.where(id: 73).first
    # 43 -> ferguson
    # 36 -> Gurbaz

    updated_playing11 = this_week_team.playing11 - [43]
    updated_playing11.push(36)
    updated_bench = rushabh.weekly_user_teams.order(week_start_date: :desc).first.bench - [36]
    updated_bench.push(43)

    this_week_team.update_columns(playing11: updated_playing11, bench: updated_bench)
  end
end
