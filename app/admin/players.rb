# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength, Layout/LineLength
ActiveAdmin.register Player do
  permit_params :name, :other_names, :base_price, :team_name, :cricbuzz_player_id, :foreigner, :team_ids, :image, :role, :replacement_of

  config.sort_order = 'id_desc'

  filter :name
  filter :teams_id, as: :select, collection: -> { Team.pluck(:team_name, :id) }, label: 'Team'
  filter :role, as: :select, collection: -> { Player.roles }, include_blank: 'Select Role'
  # filter :teams, as: :select, collection: -> { Team.pluck(:team_name, :id) }, include_blank: 'Select Team'
  filter :team_name, as: :select, collection: -> { Player.pluck(:team_name).uniq }
  filter :foreigner

  index do
    selectable_column
    id_column
    column :name
    column :Team do |player|
      player&.teams.pluck(:team_name).join(', ')
    end
    column :IPL_Team, &:team_name
    column :role
    column :cricbuzz_player_id
    # column :other_names do |player|
    #   player&.other_names&.join(', ')
    # end
    # column :sold_price
    # column :foreigner
    actions
  end

  form do |f|
    f.inputs 'Player Details' do
      f.input :name
      f.input :replacement_of
      f.input :role, as: :select, include_blank: 'Select Role'
      f.input :team_name, as: :select, collection: [
        ['Chennai Super Kings', 'CSK'],
        ['Rajasthan Royals' , 'RR'],
        ['Kolkata Knight Riders', 'KKR'],
        ['Sunrisers Hyderabad', 'SRH'],
        ['Royal Challengers Bengaluru', 'RCB'],
        ['Delhi Capitals', 'DC'],
        ['Punjab Kings', 'PBKS'],
        ['Mumbai Indians', 'MI'],
        ['Gujarat Titans', 'GT'],
        ['Lucknow Super Giants', 'LSG']
        # ['Melbourne Renegades', 'MR'],
        # [' Perth Scorchers', 'PS'],
        # ['Sydney Sixers', 'SYS'],
        # ['Melbourne Stars', 'MLS']
        # ['India', 'IND'],
        # ['Australia', 'AUS'],
        # ['Bangladesh', 'BAN'],
        # ['England', 'ENG'],
        # ['New Zealand', 'NZ'],
        # ['Pakistan', 'PAK'],
        # ['South Africa', 'RSA'],
        # ['Sri Lanka', 'SL'],
        # ['West Indies', 'WI'],
        # ['AFGANISTAN', 'AFG'],
        # ['Canada', 'CA'],
        # ['Ireland', 'IRE'],
        # ['Namibia', 'NAM'],
        # ['Nepal', 'NEP'],
        # ['Netherlands', 'NETH'],
        # ['Oman', 'OMN'],
        # ['Papua New Guinea', 'PNG'],
        # ['Scotland', 'SCOT'],
        # ['Uganda', 'UG'],
        # [' United States', 'USA'],
        # ['Srilanka', 'SL']
      ], include_blank: 'Select Team'
      f.input :cricbuzz_player_id
      # f.input :other_names, as: :string, input_html: { value: f.object.other_names.join(', ') }, hint: 'Enter comma-separated values'
      f.input :teams, as: :select, collection: Team.all.map { |t|
                                                   [t.team_name, t.id]
                                                 }, include_blank: 'Select team of user'
      f.input :image, as: :file,
                      hint: f.object.image.attached? ? image_tag(url_for(f.object.image), class: 'admin-form-image') : content_tag(:span, 'No image yet')
      f.input :foreigner, as: :boolean
    end
    f.actions
  end

  # controller do
  #   def create
  #     params[:player][:other_names] = params[:player][:other_names].split(',').map(&:strip)
  #     super
  #   end

  #   def update
  #     params[:player][:other_names] = params[:player][:other_names].split(',').map(&:strip)
  #     super
  #   end
  # end

  show do
    attributes_table do
      row :name
      row :replacement_of
      row :Teams do |player|
        player.teams.pluck(:team_name).join(', ')
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
