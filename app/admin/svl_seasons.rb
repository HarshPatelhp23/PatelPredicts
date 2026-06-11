ActiveAdmin.register Svl::Season do
  permit_params :name, :start_date, :end_date

  # menu label: "SVL Seasons", parent: "SVL"

  index do
    selectable_column
    id_column
    column :name
    column :start_date
    column :end_date
    column("Teams") { |s| s.teams.count }
    column("Matches") { |s| s.matches.count }
    actions
  end

  show do
    attributes_table do
      row :name
      row :start_date
      row :end_date
    end

    panel "Points Table" do
      table_for resource.points_table do
        column("#")           { |t| resource.points_table.index(t) + 1 }
        column("Team")        { |t| link_to t.name, admin_svl_team_path(t) }
        column "P",           :no_of_matches_played
        column "W",           :no_of_matches_won
        column "L",           :no_of_matches_lost
        column "PTS DIFF",    :points_diff
        column "SET DIFF",    :set_diff
        column "PTS",         :points
      end
    end
  end

  form do |f|
    f.inputs "Season Details" do
      f.input :name
      f.input :start_date, as: :date_picker
      f.input :end_date,   as: :date_picker
    end
    f.actions
  end
end
