# frozen_string_literal: true

# app/admin/match_point.rb

ActiveAdmin.register MatchPoint do
  permit_params :team_id, :total_points, :match_name

  index do
    selectable_column
    id_column
    column :match_name
    column :team do |t|
      t&.team&.team_name
    end
    column :total_points
    actions
  end

  form do |f|
    f.inputs 'Match Point Details' do
      # f.input :match_id
      f.input :team_id
      f.input :total_points
    end
    f.actions
  end
  filter :team, as: :select, collection: -> { Team.pluck(:team_name, :id) }, include_blank: 'Select Team'
end
