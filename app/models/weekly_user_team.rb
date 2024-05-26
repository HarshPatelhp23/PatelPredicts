# frozen_string_literal: true

class WeeklyUserTeam < ApplicationRecord
  belongs_to :user

  validates :week_start_date, uniqueness: { scope: :user_id }

  def self.ransackable_attributes(_auth_object = nil)
    %w[bench created_at id playing11 updated_at user_id week_end_date week_start_date]
  end

  def self.current_week_changes(user_id, week, change_week) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    user = User.find(user_id)
    if week.to_i == 1
      playing_11_changed_player_id = user.weekly_user_teams.first.playing11
      bench_changed_player_id = user.weekly_user_teams.first.bench

      return [playing_11_changed_player_id, bench_changed_player_id]
    end
    all_week_records = user.weekly_user_teams.order(created_at: :asc)
    return [[], []] unless all_week_records.count == week.to_i || change_week

    current_week_record = user.weekly_user_teams.order(week_start_date: :asc)[week.to_i - 1]
    return [[], []] if current_week_record.blank?

    current_week_record_index = all_week_records.find_index(current_week_record)
    last_week_record = all_week_records[current_week_record_index - 1]
    playing_11_changed_player_id = current_week_record.playing11 - last_week_record.playing11
    bench_changed_player_id = current_week_record.bench - last_week_record.bench
    [playing_11_changed_player_id, bench_changed_player_id]
  end
end
