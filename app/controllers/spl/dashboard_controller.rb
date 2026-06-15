module Spl
  class DashboardController < ApplicationController
    before_action :authenticate_spl_user!

    def index
      @current_user_is_admin = current_spl_user.is_admin
      @spl_user = current_spl_user

      # Players grouped by category
      players_by_cat = AuctionPlayer.all.group_by(&:category)
      @players_json = players_by_cat
                        .transform_values { |arr| arr.map(&:as_json_for_team) }
                        .to_json

      @category_meta_json = AuctionPlayer::CATEGORY_META.map do |key, meta|
        { key: key.to_s, label: meta[:label], sub: meta[:sub], icon: meta[:icon] }
      end.to_json

      # Existing team
      existing_team       = @spl_user.fantasy_team || @spl_user.create_fantasy_team(playing11: [])
      @existing_playing11 = existing_team&.playing11 || []

      # Captain / VC from DB — no session
      @captain_id = existing_team&.captain_id
      @vc_id      = existing_team&.vice_captain_id

      # Leaderboard (top 50)
      lb_users = Spl::User
                   .joins(:fantasy_team)
                   .includes(:fantasy_team)
                   .select("spl_users.id, spl_users.name, spl_users.total_points")
                   .order("spl_users.total_points DESC")
                   .limit(50)

      @leaderboard_json = lb_users.each_with_index.map do |u, i|
        team = u.fantasy_team
        {
          rank:   i + 1,
          name:   u.name.presence || "Player #{i + 1}",
          points: u.total_points.to_i,
          me:     u.id == @spl_user.id,
          playing11:  team&.playing11 || [],
          captain_id: team&.captain_id,
          vc_id:      team&.vice_captain_id
        }
      end.to_json

      my_entry    = lb_users.find { |u| u.id == @spl_user.id }
      @user_rank  = my_entry ? lb_users.index(my_entry) + 1 : "—"


      # @save_url   = if existing_team.present?
      #                 spl_fantasy_team_save_path(fantasy_team_id: existing_team&.id)
      #               else
      #                 spl_dashboard_path
      #               end
      @save_url = spl_fantasy_team_save_path(existing_team)
      @csrf_token = form_authenticity_token
    end
  end
end
