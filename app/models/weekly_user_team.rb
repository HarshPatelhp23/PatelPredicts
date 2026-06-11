# frozen_string_literal: true

class WeeklyUserTeam < ApplicationRecord
  belongs_to :user
  belongs_to :team
  before_save :update_team_changes

  validates :week_start_date, uniqueness: { scope: :team_id }

  def self.ransackable_attributes(_auth_object = nil)
    %w[bench created_at id updated_at user_id week_end_date week_start_date week]
  end

  def self.current_week_changes(user, team, week, auction)
    if week == 1
      playing_11_changed_player_id = team.weekly_user_teams.first.playing11
      bench_changed_player_id = team.weekly_user_teams.first.bench

      return [playing_11_changed_player_id, bench_changed_player_id]
    end
    all_weekly_user_teams = team.weekly_user_teams
    if all_weekly_user_teams.count == week
      current_week_record = all_weekly_user_teams[week - 1]
      current_week_record_index = all_weekly_user_teams.find_index(current_week_record)
      previous_week_record = all_weekly_user_teams[current_week_record_index - 1]

      playing_11_changed_player_id = current_week_record.playing11 - previous_week_record.playing11

      bench_changed_player_id = current_week_record.bench - previous_week_record.bench
      [playing_11_changed_player_id, bench_changed_player_id]
    else
      playing_11_changed_player_id = all_weekly_user_teams.last.playing11
      bench_changed_player_id = all_weekly_user_teams.last.bench
      [playing_11_changed_player_id, bench_changed_player_id]
    end
  end

  def self.current_week_team_submitted?(user)
    current_date = Time.now.to_date
    if current_date.saturday? || current_date.sunday?
      next_sunday = current_date.next_week.end_of_week
      user.weekly_user_teams.exists?(week_end_date: next_sunday)
    else
      current_sunday = current_date.end_of_week
      user.weekly_user_teams.exists?(week_end_date: current_sunday)
    end
  end

  # def self.current_week_changes(user_id, team, week, change_week) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  #   user = User.find(user_id)
  #   if week.to_i == 1
  #     playing_11_changed_player_id = user.weekly_user_teams.where(team:).first.playing11
  #     bench_changed_player_id = user.weekly_user_teams.where(team:).first.bench

  #     return [playing_11_changed_player_id, bench_changed_player_id]
  #   end
  #   all_week_records = user.weekly_user_teams.where(team:).order(created_at: :asc)
  #   return [[], []] unless all_week_records.count == week.to_i || change_week

  #   current_week_record = user.weekly_user_teams.where(team:).order(week_start_date: :asc)[week.to_i - 1]
  #   return [[], []] if current_week_record.blank?

  #   current_week_record_index = all_week_records.find_index(current_week_record)
  #   last_week_record = all_week_records[current_week_record_index - 1]
  #   playing_11_changed_player_id = current_week_record.playing11 - last_week_record.playing11
  #   bench_changed_player_id = current_week_record.bench - last_week_record.bench
  #   [playing_11_changed_player_id, bench_changed_player_id]
  # end

  # def self.track_changes(user, team)
  #   playing_11_changed_player_id = user.weekly_user_teams.where(team:).order(week_start_date: :asc).first.playing11
  #   bench_changed_player_id = user.weekly_user_teams.where(team:).order(week_start_date: :asc).first.bench

  #   return [playing_11_changed_player_id, bench_changed_player_id] if team.weekly_user_teams.count == 1

  #   all_records = user.weekly_user_teams.where(team:).order(week_start_date: :asc)
  #   current_week_record = user.weekly_user_teams.where(team:).order(week_start_date: :asc).last
  #   record_before_current_week_index = all_records.find_index(current_week_record) - 1
  #   record_before_current_week = all_records[record_before_current_week_index]

  #   playing_11_changed_player_id = current_week_record.playing11 - record_before_current_week.playing11
  #   bench_changed_player_id = current_week_record.bench - record_before_current_week.bench
  #   [playing_11_changed_player_id, bench_changed_player_id]
  # end


  private

  def update_team_changes
    if new_record?
      self.week = next_week_number
      first_week_team = self.class.where(team:, user:).order(week: :desc)&.first || []
      puts "+++++++++++++++++++++++++++++++++++++++++++++"
      puts "+++++++++++++++++++++++++++++++++++++++++++++"
      puts "+++++++++++++++++++++++++++++++++++++++++++++"
      puts "+++++++++++++++++++++++++++++++++++++++++++++"
      puts "+++++++++++++++++++++++++++++++++++++++++++++"
      puts "+++++++++++++++++++++++++++++++++++++++++++++"
      puts "+++++++++++++++++++++++++++++++++++++++++++++"
      puts "+++++++++++++++++++++++++++++++++++++++++++++"
      puts "VALUE OF WEEK:- #{week}"
      puts "+++++++++++++++++++++++++++++++++++++++++++++"
      puts "+++++++++++++++++++++++++++++++++++++++++++++"
      puts "+++++++++++++++++++++++++++++++++++++++++++++"
      puts "+++++++++++++++++++++++++++++++++++++++++++++"
      puts "+++++++++++++++++++++++++++++++++++++++++++++"
      puts "+++++++++++++++++++++++++++++++++++++++++++++"
      puts "+++++++++++++++++++++++++++++++++++++++++++++"
      puts "+++++++++++++++++++++++++++++++++++++++++++++"
      if week == 1
        playing11_changes  = playing11
        bench_changes  = bench
      else
        playing11_changes  = first_week_team&.playing11 - playing11
        bench_changes  = first_week_team&.bench - bench
      end
      team_changes = {}
      team_changes[:playing11_changes] = playing11_changes
      team_changes[:bench_changes] = bench_changes
      self.team_changes = team_changes
    else
      week_team = self.class.where(team:, user:).order(created_at: :desc)&.second || []
      playing11_changes  =  week_team&.playing11- playing11
      bench_changes  = week_team&.bench - bench
      team_changes = {}
      team_changes[:playing11_changes] = playing11_changes
      team_changes[:bench_changes] = bench_changes
      self.team_changes = team_changes
      # self.update_columns(team_changes:)
    end
  end

  def next_week_number
    ipl_start_date = Date.strptime(Auction::IPL_FIRST_WEEK_DATE, '%d/%m/%Y')
    current_date = Date.current
    
    return 1 if current_date < ipl_start_date
    
    days_elapsed = (current_date - ipl_start_date).to_i
    (days_elapsed / 7) + 1 + 1
    #(start counting weeks from 1 instead of 0) + (for next week)
  end
end
