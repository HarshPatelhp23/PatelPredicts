# frozen_string_literal: true

ActiveAdmin.register WeeklyUserTeam do
  permit_params :user_id, :week_start_date, :week_end_date, :playing11, :bench, :week

  filter :week_start_date
  filter :week_end_date
  filter :user
  filter :week

  index do
    selectable_column
    id_column
    column :user do |record|
      record.user.username
    end
    column :team do |record|
      record.team.team_name
    end
    column :week
    column :team, 'Auction' do |record|
      record.team.auction.name
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
