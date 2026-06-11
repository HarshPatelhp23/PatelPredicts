# frozen_string_literal: true

class OwnerScoreNotifier < ApplicationMailer
  def notify_owners
    Team.all.each do |team|
    	# next if team.id != 3
      todays_matches = team.matches.where(match_date: Date.current)
      next if todays_matches.empty?

      # Group matches by match_name (each unique match played today)
      matches_by_name = todays_matches.group_by(&:match_name)

      # Build structured data per match
      match_summaries = matches_by_name.map do |match_name, match_records|

        current_weekly_team = team.weekly_user_teams.last

        playing_xi = match_records.select { |m| current_weekly_team.playing11.include?(m.player_id) }
        bench      = match_records.select { |m| current_weekly_team.bench.include?(m.player_id) }

        playing_xi_rows = playing_xi.map do |m|
          player = Player.find(m.player_id)
          { name: player.name, points: m.points }
        end

        bench_rows = bench.map do |m|
          player = Player.find(m.player_id)
          { name: player.name, points: m.bench_points }
        end

        total = match_records.sum { |m| m.points.to_f + m.bench_points.to_f }

        {
          match_name:,
          playing_xi:,
          bench:,
          total:
        }
      end

      grand_total = match_summaries.sum { |ms| ms[:total] }

      mail(
        to:      team.user.email,
        subject: "🏏 Patel-Predicts Scorecard – #{Date.current.strftime('%d %b %Y')}"
      ) do |format|
        format.html do
          render "owner_score_notifier/notify_owners",
                 locals: { team:, match_summaries:, grand_total:,
                   				 point_table_url: after_login_url(auction_id: team.auction_id)
                				 }
        end
      end
    end
  end
end
