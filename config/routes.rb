# frozen_string_literal: true
require 'sidekiq/web'
require 'sidekiq/cron/web'

Rails.application.routes.draw do
  mount ActionCable.server, at: '/cable'
  mount Sidekiq::Web => '/sidekiq'
  devise_for :admin_users, ActiveAdmin::Devise.config
  devise_for :users, controllers: {
    registrations: 'users/registrations',
    sessions: 'users/sessions'
  }

  namespace :spl do
    # Dashboard - this should be the root for authenticated users
    get 'dashboard', to: 'dashboard#index'
    root to: 'dashboard#index'  # This sets /spl as the dashboard
    
    # Fantasy Teams
    resources :fantasy_teams do
      post :save
      get :leaderboard
    end
  end
  # =============================================
  # SPL (SUGAM PREMIER LEAGUE) AUTHENTICATION
  # =============================================
  devise_for :spl_users, 
             class_name: 'Spl::User',           # Namespaced model
             module: :devise,                   # Use Devise modules
             path: 'spl',                       # URL prefix: /spl
             controllers: {
               sessions: 'spl/sessions',        # Custom sessions controller
               registrations: 'spl/registrations', # Custom registrations controller
               passwords: 'spl/passwords',      # Custom passwords controller
               confirmations: 'spl/confirmations'  # Custom confirmations controller
             }
  
  # =============================================
  # CUSTOM SPL OTP ROUTES
  # =============================================
  devise_scope :spl_user do
    # OTP Login Routes
    get 'spl/otp_login', to: 'spl/sessions#otp_login', 
        as: :otp_login_spl_user_session
    
    post 'spl/send_otp_login', to: 'spl/sessions#send_otp_login',
        as: :send_otp_login_spl_user_session
    
    post 'spl/verify_otp_login', to: 'spl/sessions#verify_otp_login',
        as: :verify_otp_login_spl_user_session
    
    # OTP Registration Routes
    post 'spl/send_otp', to: 'spl/registrations#send_otp',
        as: :send_otp_spl_user_registration
    
    post 'spl/verify_otp', to: 'spl/registrations#verify_otp',
        as: :verify_otp_spl_user_registration
  end
  resources :teams, only: [:create] do
    get 'new/:team_id', to: 'teams#new', as: 'new_team'
    put 'update_playing_11/:player_id', to: 'teams#update_playing_11', as: 'update_playing11'
  end
  resources :auctions
  resources :push_subscriptions, only: [:create]
  resources :firebase_registrations, only: [:create]
  resources :auction_bids, only: [:create]
  resources :players do
    member do
      get :statistics
      post :sync_statistics
    end
  end

  namespace :svl do
    resources :matches, only: [:index]
    get  'points_table', to: 'points_table#index', as: :points_table
    get  'score_match', to: 'matches#score_match', as: :score_match
    post 'save_match',  to: 'matches#save_match',  as: :save_match
  end

  get 'manifest.json', to: 'push_subscriptions#manifest'
  get 'vapid_public_key', to: 'push_subscriptions#vapid_public_key'

  get '/players_by_team', to: 'home#players_by_team'
  get 'points_table', to: 'home#points_table'
  get '/bench_points_table', to: 'home#bench_points_table'
  get '/points_system', to: 'matches#point_system'

  root 'home#welcome'
  #---------------------------------------
  get '/auction_table', to: 'auctions#auction_table'
  get 'trades/available', to: 'auctions#available_trades', as: :available_trades
  get '/spin_wheel', to: 'auctions#speen_wheel'
  get '/:auction_id/squads', to: 'auctions#squads', as: :squads
  patch '/teams/:id/update_purse', to: 'teams#update_purse'
  get '/team_auction_table', to: 'auctions#team_auction_table'
  get '/player/:id', to: 'auctions#get_player', as: 'get_player'
  get 'current_auction_state', to: 'auctions#current_auction_state'
  get 'auctions/:auction_id/teams', to: 'auctions#fetch_teams'
  get '/auction_list', to: 'auctions#auction_list'
  get '/spl_head_to_head', to: 'auctions#spl_head_to_head'
  get '/hotpicks', to: 'auctions#auction_hotpicks'
  post '/auction_table', to: 'auctions#validate_code', as: 'validate_code'
  get '/spl_insights', to: 'auctions#spl_insights'
  get '/spl_orange_cap', to: 'auctions#spl_orange_cap'
  get '/spl_purple_cap', to: 'auctions#spl_purple_cap'
  get '/category_wise_players', to: 'auctions#spl_categories'
  post '/update_view_preference', to: 'auctions#update_view_preference'

  #------------------------------------

  post '/live_auction/:player_id', to: 'home#live_auction', as: 'home_live_auction'
  get '/live_auction', to: 'home#live_auction'
  #--------------------------------------------------------------------------------------
  post '/create_team', to: 'teams#create', as: 'create_team'
  get '/after_login', to: 'home#after_login'
  get '/contests_list', to: 'auctions#contests_list', as: :contests

   #--------------------------------------------------------------------------------------

  get '/chatbot', to: 'chatbot#index'
  post '/chatbot/chat', to: 'chatbot#chat'

   #--------------------------------------------------------------------------------------

  get 'verify_otp/:user_slug', to: 'home#verify_otp', as: 'verify_otp'
  post 'verify_otp/:user_slug', to: 'home#process_otp', as: 'verify_otp_process'
  get 'resend_otp/:user_slug', to: 'home#resend_otp', as: 'resend_otp'

  get 'scorecard_for_day/:match_id', to: 'home#one_match_scorecard', as: 'one_match_scorecard'
  get 'team_score/:match_name/:auction_id', to: 'home#compute_match_team_points', as: 'compute_match_team_points'
  get 'other/players_team', to: 'teams#other_player_teams'
  get 'other/:user_slug/team_details', to: 'teams#other_players_team_detail', as: 'team_deatails'
  get 'playing11', to: 'teams#playing_11'
  get 'bench_players', to: 'teams#bench_players'
  post '/submit_team', to: 'teams#submit_team'
  # post 'submit_team', to: 'teams#submit_team', as: 'submit_team'
  get '/team_analysis', to: 'teams#analysis'
  get ':user_slug/edit_profile', to: 'home#edit_profile', as: 'edit_profile'
  post 'update_profile', to: 'home#update_profile', as: 'update_profile'
  post 'update_profile_picture', to: 'home#update_profile_picture'
  get '/team_performance', to: 'teams#team_performance', as: 'team_performance'
  get '/:player_id/player_performance', to: 'teams#player_data', as: 'player_data'
  # get '/players/:player_id', to: 'teams#show', as: 'player_profile'
  get '/search_players', to: 'teams#search_players'
  get '/power_perfomers', to: 'teams#power_perfomers', as: 'power_perfomers'
  get 'match_schedule', to: 'matches#current_week_schedule', as: 'current_week_schedule'
  get ':user_id/:match_name/players', to: 'matches#match_players', as: 'match_players'

  post '/teams/move_players', to: 'teams#move_players'

  # get '/auction_table', to: 'home#auction_table'
  ActiveAdmin.routes(self)
end
