# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength, Layout/LineLength
ActiveAdmin.register Player do
  permit_params :name, :base_price, :team_name, :foreigner, :team_id, :points, :image, :role

  config.sort_order = 'points_desc'

  filter :name
  filter :points
  filter :role, as: :select, collection: -> { Player.roles }, include_blank: 'Select Role'
  filter :team, as: :select, collection: -> { Team.pluck(:team_name, :id) }, include_blank: 'Select Team'
  filter :foreigner

  index do
    selectable_column
    id_column
    column :name
    column :points
    column :Team do |player|
      player&.team&.team_name
    end
    column :IPL_Team, &:team_name
    column :role
    column :foreigner
    actions
  end

  form do |f|
    f.inputs 'Player Details' do
      f.input :name
      f.input :points
      f.input :role, as: :select, include_blank: 'Select Role'
      f.input :team_name, as: :select, collection: [
        ['Mumbai Indians', 'MI'],
        ['Chennai Super Kings', 'CSK'],
        ['Delhi Capitals', 'DC'],
        ['Royal Challengers Bangalore', 'RCB'],
        ['Kolkata Knight Rider', 'KKR'],
        ['Punjab Kings', 'PBKS'],
        ['Gujarat Titans', 'GT'],
        ['Lucknow Super Giants', 'LSG'],
        ['Sunrisers Hyderabad', 'SRH'],
        ['Rajasthan Royals', 'RR']
      ], include_blank: 'Select Team'
      f.input :team_id, as: :select, collection: Team.all.map { |t|
                                                   [t.team_name, t.id]
                                                 }, include_blank: 'Select team of user'
      f.input :image, as: :file,
                      hint: f.object.image.attached? ? image_tag(url_for(f.object.image), class: 'admin-form-image') : content_tag(:span, 'No image yet')
      f.input :foreigner, as: :boolean
    end
    f.actions
  end

  show do
    attributes_table do
      row :name
      row :Team do |player|
        player.team.team_name
      end
      row :foreigner
      row :role
      row 'Image' do |player|
        if player.image.attached?
          span do
            image_tag url_for(player.image), class: 'admin-show-image'
          end
        else
          span 'No Image'
        end
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength, Layout/LineLength
