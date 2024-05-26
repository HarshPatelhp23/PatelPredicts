# frozen_string_literal: true

ActiveAdmin.register Match, as: 'Match' do
  permit_params :match_name, :player_id, :points, :team_id, :auction_id

  index do
    selectable_column
    id_column
    column :match_name
    column :player do |match|
      match&.player&.name || 'Bench/No Player'
    end
    column :points
    column :team_id do |match|
      match&.team&.team_name
    end
    actions
  end

  form do |f|
    f.inputs 'Match Details' do
      f.input :match_name
      f.input :auction_id, as: :select, collection: Auction.all.map { |auc| [auc.name, auc.id] }
      f.input :team_id, as: :select, collection: Team.all.map { |t| [t.team_name, t.id] }, include_blank: true
      f.input :player_id, as: :select, collection: [], include_blank: 'Please select Team first'
      f.input :points
    end
    f.actions
  end
end
