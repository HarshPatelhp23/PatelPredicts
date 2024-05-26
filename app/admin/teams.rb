# frozen_string_literal: true

ActiveAdmin.register Team do
  permit_params :team_name, :user_id

  index do
    selectable_column
    id_column
    column :team_name
    column :user do |team|
      team.user.username
    end
    column :players do |team|
      team.players.pluck(:name)
    end
    actions
  end

  filter :team_name
  filter :players
end
