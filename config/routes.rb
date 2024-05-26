# frozen_string_literal: true

Rails.application.routes.draw do
  devise_for :admin_users, ActiveAdmin::Devise.config
  devise_for :users, controllers: {
    registrations: 'users/registrations',
    sessions: 'users/sessions'
  }
  resources :teams, only: [:create] do
    get 'new/:team_id', to: 'teams#new', as: 'new_team'
    put 'update_playing_11/:player_id', to: 'teams#update_playing_11', as: 'update_playing11'
  end
  resources :auctions
  resources :push_notifications

  get '/players_by_team', to: 'home#players_by_team'
  get 'points_table', to: 'home#points_table'

  root 'home#welcome'

  post '/live_auction/:player_id', to: 'home#live_auction', as: 'home_live_auction'
  get '/live_auction', to: 'home#live_auction'
  #--------------------------------------------------------------------------------------
  post '/create_team', to: 'teams#create', as: 'create_team'
  get '/after_login', to: 'home#after_login'

  get 'verify_otp/:user_slug', to: 'home#verify_otp', as: 'verify_otp'
  post 'verify_otp/:user_slug', to: 'home#process_otp', as: 'verify_otp_process'
  get 'resend_otp/:user_slug', to: 'home#resend_otp', as: 'resend_otp'

  get 'scorecard_for_day/:match_id', to: 'home#one_match_scorecard', as: 'one_match_scorecard'
  get 'team_score/:match_name', to: 'home#compute_match_team_points', as: 'compute_match_team_points'
  get 'other/players_team', to: 'teams#other_player_teams'
  get 'other/:user_slug/team_details', to: 'teams#other_players_team_detail', as: 'team_deatails'
  get 'playing11', to: 'teams#playing_11'
  get 'bench_players', to: 'teams#bench_players'
  post '/submit_team', to: 'teams#submit_team'
  get '/team_analysis', to: 'teams#analysis'
  get ':user_slug/edit_profile', to: 'home#edit_profile', as: 'edit_profile'
  post 'update_profile', to: 'home#update_profile', as: 'update_profile'
  get '/team_performance', to: 'teams#team_performance', as: 'team_performance'
  get '/:player_id/player_performance', to: 'teams#player_data', as: 'player_data'
  get '/search_players', to: 'teams#search_players'
  get '/power_perfomers', to: 'teams#power_perfomers', as: 'power_perfomers'
  get 'match_schedule', to: 'matches#current_week_schedule', as: 'current_week_schedule'
  get ':user_id/:match_name/players', to: 'matches#match_players', as: 'match_players'

  post '/teams/move_players', to: 'teams#move_players'

  # get '/auction_table', to: 'home#auction_table'
  ActiveAdmin.routes(self)
  # mount ActionCable.server => '/cable'
end
