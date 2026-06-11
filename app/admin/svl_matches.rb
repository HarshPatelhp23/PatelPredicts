# app/admin/svl_matches.rb
ActiveAdmin.register Svl::Match, as: "SvlMatch" do
  permit_params :season_id, :winning_team_id, :losing_team_id,
                :winning_team_points, :losing_team_points,
                :winning_team_sets, :losing_team_sets, :played_on

  menu label: "SVL Matches", parent: "SVL"

  filter :season,        as: :select, collection: -> { Svl::Season.all.map { |s| [s.name, s.id] } }
  filter :winning_team,  as: :select, collection: -> { Svl::Team.all.map { |t| [t.name, t.id] } }
  filter :losing_team,   as: :select, collection: -> { Svl::Team.all.map { |t| [t.name, t.id] } }
  filter :played_on

  index do
    selectable_column
    id_column
    column :season
    column :played_on
    column("Winner")   { |m| m.winning_team&.name }
    column("Loser")    { |m| m.losing_team&.name }
    column("Sets")     { |m| "#{m.winning_team_sets} – #{m.losing_team_sets}" }
    column("Points")   { |m| "#{m.winning_team_points} – #{m.losing_team_points}" }
    actions
  end

  show do
    attributes_table do
      row :season
      row :played_on
      row("Winner")         { resource.winning_team&.name }
      row("Loser")          { resource.losing_team&.name }
      row("Total points")   { "#{resource.winning_team_points} – #{resource.losing_team_points}" }
      row("Sets")           { "#{resource.winning_team_sets} – #{resource.losing_team_sets}" }
    end

  panel "Set by Set Scores" do
    table_for resource.match_sets.order(:set_number) do
      column "Set",             :set_number
      column "Winner score",    :winning_team_score
      column "Loser score",     :losing_team_score
    end

    div do
      strong "Total: "
      span "#{resource.winning_team_points} – #{resource.losing_team_points}"
    end
  end
end

  form do |f|
    f.inputs "Match Details" do
      f.input :season, as: :select,
              collection: Svl::Season.all.map { |s| [s.name, s.id] }

      f.input :played_on, as: :date_picker

      f.input :winning_team, as: :select,
              collection: Svl::Team.all.map { |t| ["#{t.name} (#{t.season.name})", t.id] }

      f.input :winning_team_sets,   label: "Winning team sets"

      f.input :losing_team, as: :select,
              collection: Svl::Team.all.map { |t| ["#{t.name} (#{t.season.name})", t.id] }

      f.input :losing_team_sets,   label: "Losing team sets"
    end
    f.actions
  end
end
