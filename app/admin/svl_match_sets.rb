# app/admin/svl_match_sets.rb
ActiveAdmin.register Svl::MatchSet, as: "SvlMatchSet" do
  permit_params :match_id, :set_number, :winning_team_score, :losing_team_score

  menu label: "SVL Match Sets", parent: "SVL"

  filter :match_id
  filter :set_number

  index do
    selectable_column
    id_column
    column :match do |s|
      "#{s.match.winning_team&.name} vs #{s.match.losing_team&.name}"
    end
    column :set_number
    column :winning_team_score
    column :losing_team_score
    actions
  end

  show do
    attributes_table do
      row :match
      row :set_number
      row :winning_team_score
      row :losing_team_score
    end
  end

  form do |f|
    f.inputs "Set Details" do
      f.input :match, as: :select,
              collection: Svl::Match.all.map { |m|
                ["#{m.winning_team&.name} vs #{m.losing_team&.name} (#{m.played_on})", m.id]
              }
      f.input :set_number
      f.input :winning_team_score
      f.input :losing_team_score
    end
    f.actions
  end
end
