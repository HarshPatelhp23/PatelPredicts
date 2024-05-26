# frozen_string_literal: true

ActiveAdmin.register WeeklyUserTeam do
  permit_params :user_id, :week_start_date, :week_end_date, :playing11, :bench

  filter :week_start_date
  filter :week_end_date
  filter :user

  index do
    selectable_column
    id_column
    column :user do |record|
      record.user.username
    end
    column :week_start_date
    column :week_end_date
    column :playing11 do |record|
      ids = record.playing11
      Player.where(id: ids).map(&:name)
    end
    column :bench do |record|
      ids = record.bench
      Player.where(id: ids).map(&:name)
    end
    actions
  end
end
