module Spl
  class FantasyTeamsController < BaseController
    def show
      @fantasy_team = current_spl_user.fantasy_team
    end
    
    def edit
      @fantasy_team = current_spl_user.fantasy_team
    end
    
    def update
      @fantasy_team = current_spl_user.fantasy_team
      if @fantasy_team.update(fantasy_team_params)
        redirect_to spl_dashboard_path, notice: 'Fantasy team updated successfully!'
      else
        render :edit
      end
    end

    def leaderboard
      users = Spl::User
                .joins(:fantasy_team)
                .select("spl_users.id, spl_users.name, spl_users.final_total_points")
                .order("spl_users.final_total_points DESC")

      data = users.each_with_index.map do |u, i|
        {
          rank:   i + 1,
          name:   u.name.presence || "Player #{i + 1}",
          points: u.final_total_points.to_i,
          me:     u.id == current_spl_user.id
        }
      end

      render json: data
    end

    # POST /spl/fantasy_teams/save
    def save
      playing11  = Array(params[:playing11]).map(&:to_i).uniq
      captain_id = params[:captain_id].to_i
      vc_id      = params[:vc_id].to_i
      # fantasy_team = current_spl_user.fantasy_team

      fantasy_team = current_spl_user.fantasy_team ||
             Spl::FantasyTeam.new(spl_user: current_spl_user)

      errors = fantasy_team.errors.full_messages&.join(', ')
      if errors.present?
        render json: { success: false, errors: errors }, status: :unprocessable_entity
        return
      end
      fantasy_team.playing11       = playing11
      fantasy_team.captain_id      = captain_id
      fantasy_team.vice_captain_id = vc_id
      fantasy_team.team_name       = params[:team_name].presence || "#{current_spl_user.name}'s XI"
      if fantasy_team.save
        render json: { success: true, message: "Team saved successfully!" }
      else
        puts "+++++++++++++++++++++++++++++++++++++++++"
        puts "+++++++++++++++++++++++++++++++++++++++++"
        puts "+++++++++++++++++++++++++++++++++++++++++"
        puts "+++++++++++++++++++++++++++++++++++++++++"
        puts "+++++++++++++++++++++++++++++++++++++++++"
        puts "+++++++++++++++++++++++++++++++++++++++++"
        puts "ERRORS:- #{team.errors.full_messages}"
        puts "+++++++++++++++++++++++++++++++++++++++++"
        puts "+++++++++++++++++++++++++++++++++++++++++"
        puts "+++++++++++++++++++++++++++++++++++++++++"
        puts "+++++++++++++++++++++++++++++++++++++++++"
        render json: { success: false, errors: team.errors.full_messages }, status: :unprocessable_entity
      end
    end
    
    private
    
    def fantasy_team_params
      params.require(:fantasy_team).permit(:team_name, playing11: [])
    end
  end
end
