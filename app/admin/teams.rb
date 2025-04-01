# frozen_string_literal: true

ActiveAdmin.register Team do
  permit_params :team_name, :user_id, :auction_id

  index do
    selectable_column
    id_column
    column :team_name
    column :user do |team|
      team.user.username
    end
    column :grand_total
    column :email, label: 'Email' do |team|
      team.user.email
    end
    column :players do |team|
      team.players.pluck(:name)
    end
    column :auction do |team|
      team&.auction&.name
    end
    actions
  end

  controller do
    def find_resource
      Team.friendly.find(params[:id])
    end
  end

  form do |f|
    f.inputs 'Player Details' do
      f.input :team_name
      f.input :user, as: :select, collection: User.all.map { |u| [u.username, u.id] }, include_blank: 'Select user'
      f.input :auction, as: :select, collection: Auction.all.map { |a| [a.name, a.id] }, include_blank: 'Select Auction'
    end
    f.actions
  end

  filter :team_name
  filter :players_name_cont, as: :string, label: 'Player Name'
end
