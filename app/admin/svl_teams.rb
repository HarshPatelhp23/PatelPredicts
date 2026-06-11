# app/admin/svl_teams.rb
ActiveAdmin.register Svl::Team, as: "SvlTeam" do
  permit_params :season_id, :name

  menu label: "SVL Teams", parent: "SVL"

  filter :season,         as: :select, collection: -> { Svl::Season.all.map { |s| [s.name, s.id] } }
  filter :name

  index do
    selectable_column
    id_column
    column :season
    column :name
    column "P", :no_of_matches_played
    column "W", :no_of_matches_won
    column "L", :no_of_matches_lost
    column "PTS DIFF", :points_diff
    column "SET DIFF", :set_diff
    column "PTS", :points
    actions
  end

  show do
    attributes_table do
      row :season
      row :name
      row("P") { resource.no_of_matches_played }
      row("W") { resource.no_of_matches_won }
      row("L") { resource.no_of_matches_lost }
      row("Points diff") { resource.points_diff }
      row("Set diff")    { resource.set_diff }
      row("Points")      { resource.points }
    end

    panel "Matches Won" do
      table_for resource.won_matches.order(played_on: :desc) do
        column("vs")          { |m| link_to m.losing_team&.name, admin_svl_match_path(m) }
        column :played_on
        column("Score")       { |m| "#{m.winning_team_sets} – #{m.losing_team_sets}" }
        column("PTS")         { |m| "#{m.winning_team_points} – #{m.losing_team_points}" }
      end
    end

    panel "Matches Lost" do
      table_for resource.lost_matches.order(played_on: :desc) do
        column("vs")          { |m| link_to m.winning_team&.name, admin_svl_match_path(m) }
        column :played_on
        column("Score")       { |m| "#{m.losing_team_sets} – #{m.winning_team_sets}" }
        column("PTS")         { |m| "#{m.losing_team_points} – #{m.winning_team_points}" }
      end
    end
  end

  form do |f|
    f.inputs "Team Details" do
      f.input :season, as: :select, collection: Svl::Season.all.map { |s| [s.name, s.id] }
      f.input :name
    end
    f.actions
  end
end
