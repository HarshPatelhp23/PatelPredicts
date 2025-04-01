# frozen_string_literal: true

class WeeklyUserTeam < ApplicationRecord
  belongs_to :user
  belongs_to :team
  before_save :update_team_changes

  validates :week_start_date, uniqueness: { scope: :team_id }

  def self.ransackable_attributes(_auth_object = nil)
    %w[bench created_at id playing11 updated_at user_id week_end_date week_start_date week]
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
    return unless new_record?

    playing11_changes  = self.class.where(team:, user:).order(week_start_date: :desc)&.last.playing11 - playing11
    bench_changes  = self.class.where(team:, user:).order(week_start_date: :desc)&.last.bench - bench
    team_changes = {}
    team_changes[:playing11_changes] = playing11_changes
    team_changes[:bench_changes] = bench_changes
    last_week = self.class.where(team:, user:).order(week_start_date: :desc)&.first.week
    self.team_changes = team_changes
    self.week = last_week + 1
  end
end
