# frozen_string_literal: true

class AuctionsController < ApplicationController
  helper_method :calculate_career_stats, :calculate_seasons_played
  include ApplicationHelper
  def show
    @auction = Auction.find(params[:id])
  end

  def new
    @auction = Auction.new
  end

  def create
    @auction = Auction.create(auction_params)
  end

  def squads
    @auction = Auction.find(params[:auction_id])
    @teams = @auction.teams.includes(:user, :players)
  end

  def available_trades
    @user = current_user
    @team = @user.teams&.first
    
    unless @team
      redirect_to root_path, alert: "You don't have a team yet"
      return
    end
    
    @my_players = @team.players.includes(:players_teams)
    @trade_opportunities = build_trade_opportunities(@my_players)

    respond_to do |format|
      format.html
      format.csv do
        send_data generate_csv(@trade_opportunities), 
                  filename: "trade-opportunities-#{Date.today}.csv",
                  type: 'text/csv'
      end
    end
  end

  def get_player
    player = Player.find(params[:id])
    render json: {
      id: player.id,
      name: player.name,
      base_price: player.base_price
    }
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Player not found' }, status: :not_found
  end

  # def speen_wheel
  #   # @players = Player.where.not(
  #   #   id: PlayersTeam.select(:player_id).distinct
  #   # ).map do |p|
  #   @players = Player.all.sample(10).map do |player|
  #     image_path = Rails.root.join("app/assets/images/#{player&.name}.jpeg")
  #     if File.exist?(image_path)
  #       image_tag "#{player&.name}.jpeg", class: "mt-3"
  #     else
  #       image_tag "default_player_image.jpeg", class: "player-image mb-3", alt: "Default Player Image"
  #     end
  #     {
  #       id: p.id,
  #       name: p.name,
  #       team_name: p.team_name.downcase,
  #       color: ['#FF6B6B', '#4ECDC4', '#FFE66D', '#95E1D3', '#F38181', '#AA96DA'].sample,
  #       image: image_path.present? ? image_path : nil
  #     }
  #   end
  # end

  #WORKING ONE
  # def speen_wheel
  #   @players = Player.where.not(
  #     id: PlayersTeam.select(:player_id).distinct
  #   ).map do |player|
  #   # @players = Player.where(id: [155..161]).map do |player|
  #     image_filename = "#{player.name.parameterize}.jpg"
  #     image_path = Rails.root.join("app", "assets", "images", "ipl", image_filename)
      
  #     {
  #       id: player.id,
  #       name: player.name,
  #       team_name: player.team_name,
  #       role: player.role.titleize,
  #       batting_style: player.batting_style,
  #       bowling_style: player.bowling_style,
  #       # Store just the filename, let view generate full URL
  #       image_filename: File.exist?(image_path) ? image_filename : nil,
  #       color: ['#FF6B6B', '#4ECDC4', '#FFE66D', '#95E1D3', '#F38181', '#AA96DA'].sample
  #     }
  #   end
  # end


  #FULLY WORKING ONE
  def speen_wheel
    priority_teams = ['IND', 'SL', 'PAK', 'AUS', 'ENG', 'NZ', 'WI', 'SA', 'AFG']
    @players = Player.where.not(
      id: PlayersTeam.select(:player_id).distinct
    ).map do |player|
    # @players = Player.where(id: [528..540]).map do |player|
      image_filename = "#{player.name.parameterize}.jpg"
      image_path = Rails.root.join("app", "assets", "images", "ipl", image_filename)
      
      # Fetch player statistics
      stats = player.player_statistic
      
      {
        id: player.id,
        name: player.name,
        team_name: player.team_name,
        role: player.role.titleize,
        batting_style: player.batting_style,
        bowling_style: player.bowling_style,
        image_filename: File.exist?(image_path) ? image_filename : nil,
        color: ['#FF6B6B', '#4ECDC4', '#FFE66D', '#95E1D3', '#F38181', '#AA96DA'].sample,
        # Add T20 stats
        stats: stats ? {
          # Batting Stats
          matches: stats.t20_matches || '-',
          innings: stats.t20_innings || '-',
          runs: stats.t20_runs || '-',
          balls: stats.t20_balls || '-',
          highest: stats.t20_highest || '-',
          average: stats.t20_average&.to_f&.round(2) || '-',
          strike_rate: stats.t20_strike_rate&.to_f&.round(2) || '-',
          not_out: stats.t20_not_out || '-',
          fours: stats.t20_fours || '-',
          sixes: stats.t20_sixes || '-',
          ducks: stats.t20_ducks || '-',
          fifties: stats.t20_fifties || '-',
          hundreds: stats.t20_hundreds || '-',
          # Bowling Stats
          bowling_innings: stats.t20_bowling_innings || '-',
          bowling_balls: stats.t20_bowling_balls || '-',
          bowling_runs: stats.t20_bowling_runs || '-',
          bowling_wickets: stats.t20_bowling_wickets || '-',
          bowling_average: stats.t20_bowling_average&.to_f&.round(2) || '-',
          bowling_economy: stats.t20_bowling_economy&.to_f&.round(2) || '-',
          bowling_strike_rate: stats.t20_bowling_strike_rate&.to_f&.round(2) || '-',
          best_bowling: stats.t20_best_bowling_innings || '-',
          four_wickets: stats.t20_four_wickets || '-',
          five_wickets: stats.t20_five_wickets || '-'
        } : nil
      }
    end
  end

  def team_auction_table
    @auctions = Auction.all
    @players = Player.all
    
    # If you want to show teams for a specific auction (first auction by default)
    if params[:auction_id].present?
      @auction = Auction.find(params[:auction_id])
      @teams = @auction.teams.includes(:user).limit(10)
    elsif @auctions.any?
      @auction = @auctions.first
      @teams = @auction.teams.includes(:user).limit(10)
    end
  end

  def fetch_teams
    auction = Auction.find(params[:auction_id])
    teams = auction.teams.includes(:user).limit(10)
    
    render json: teams.map { |team| 
      {
        id: team.id,
        team_name: team.team_name,
        owner_name: team.user&.username || 'Owner',
        remaining_purse: team.user&.remaining_purse || 0
      }
    }
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Auction not found' }, status: :not_found
  end

  def auction_table
    users = User.captains.sort_by { |user| TeamSkillEvaluator.calculate_winning_chances(user) }
    @users = users.sort_by { |user| TeamSkillEvaluator.calculate_winning_chances(user) }.reverse
    # @users = User.limit(4) # Fetch first 4 users
    # @user_1, @user_2, @user_3, @user_4 = @users
    @auction_rooms = AuctionRoom.all
    flash.now[:notice] = 'Welcome to SVL-1 AuctionRoom'
  end

  def validate_code
    if params[:code] == AuctionRoom::AUCTIONROOMCODE
      render json: { redirect_url: auction_table_path }, status: :ok
    else
      render json: { error: 'Invalid code' }, status: :unprocessable_entity
    end
  end

  def contests_list
    @contests = Auction.all
  end

  def spl_head_to_head
    @player1 = AuctionPlayer.find_by(id: params[:player1_id]) || AuctionPlayer.first
    @player2 = AuctionPlayer.find_by(id: params[:player2_id]) || AuctionPlayer.last


    data_analyzer = DataAnalyzer.new
    
    # Get all available SPL seasons from the CSV files
    spl_seasons = Dir.glob(Rails.root.join('lib', 'spl_data', '*_batting.csv')).map { |f| File.basename(f).split('_').first }.uniq
    
    @selected_season = params[:season] || 'all'
    
    if @selected_season == 'all'
      seasons_to_analyze = spl_seasons
    else
      seasons_to_analyze = [@selected_season]
    end
    
    # Get player batting and bowling data
    @player1_batting = data_analyzer.fetch_combined_batting_data(*seasons_to_analyze).find { |p| p[:player_name] == @player1.name }
    @player2_batting = data_analyzer.fetch_combined_batting_data(*seasons_to_analyze).find { |p| p[:player_name] == @player2.name }
    
    @player1_bowling = data_analyzer.fetch_combined_bowling_data(*seasons_to_analyze).find { |p| p[:player_name] == @player1.name }
    @player2_bowling = data_analyzer.fetch_combined_bowling_data(*seasons_to_analyze).find { |p| p[:player_name] == @player2.name }
    
    # Get head-to-head matchup data (you'll need to implement this method in DataAnalyzer)
    @head_to_head_stats = data_analyzer.fetch_head_to_head_stats(@player1.name, @player2.name, seasons_to_analyze)
    
    @spl_seasons = spl_seasons
  end

  def spl_insights
    @auction_players = AuctionPlayer.all

    # Fetch SPL data for each season
    spl4_data = DataAnalyzer.new.fetch_data_by_prefix('spl4')
    spl5_data = DataAnalyzer.new.fetch_data_by_prefix('spl5')
    spl6_data = DataAnalyzer.new.fetch_data_by_prefix('spl6')
    spl7_data = DataAnalyzer.new.fetch_data_by_prefix('spl7')
    spl8_data = DataAnalyzer.new.fetch_data_by_prefix('spl8')
    spl9_data = DataAnalyzer.new.fetch_data_by_prefix('spl9')
    spl10_data = DataAnalyzer.new.fetch_data_by_prefix('spl10')

    # Merge SPL data into @auction_players
    @auction_players = @auction_players.map do |player|
      # Initialize player hash
      player_data = player.attributes.symbolize_keys

      # Add SPL-4, SPL-5, SPL-6, SPL-7, SPL-8 data
      %w[spl4 spl5 spl6 spl7 spl8 spl9 spl10].each do |spl|
        data_source = eval("#{spl}_data")

        # Find the player data by matching player name (case-sensitive)
        player_spl_data = data_source[:batting].find { |entry| entry[:player_name] == player_data[:name] } || {}
        # Batting Fields - Use 0 instead of '-' for consistent calculation
        player_data.merge!(
          "#{spl}_run": player_spl_data[:runs] || 0,
          "#{spl}_ball": player_spl_data[:balls] || 0,
          "#{spl}_sr": player_spl_data[:sr] || 0,
          "#{spl}_highest_score": player_spl_data[:highest_score] || 0,
          # "#{spl}_matches": player_spl_data[:matches_played] || 0,
          "#{spl}_fifties": player_spl_data[:fifties] || 0,
          "#{spl}_hundreds": player_spl_data[:hundreds] || 0,
          "#{spl}_sixes": player_spl_data[:sixes] || 0,
          "#{spl}_fours": player_spl_data[:fours] || 0
        )

        # Bowling Fields - Use 0 instead of '-' for consistent calculation
        player_spl_data_bowling = data_source[:bowling].find { |entry| entry[:player] == player_data[:name] } || {}
        player_data.merge!(
          "#{spl}_innings": player_spl_data_bowling[:innings] || 0,
          "#{spl}_matches": player_spl_data[:matches_played] || 0,
          "#{spl}_wickets": player_spl_data_bowling[:wickets] || 0,
          "#{spl}_econ": player_spl_data_bowling[:econ] || 0,
          "#{spl}_overs": player_spl_data_bowling[:overs] || 0,
          "#{spl}_runs_given": player_spl_data_bowling[:runs_given] || 0,
          "#{spl}_maidens": player_spl_data_bowling[:maidens] || 0
        )
      end

      # Calculate rating using the service
      player_data[:overall_rating] = PlayerRatingCalculator.calculate(player_data)
      
      player_data
    end
  end

  def spl_categories
    session[:player_view] ||= 'table'
    @current_view = session[:player_view]
    @auction_players = AuctionPlayer.all
    
    # Fetch SPL data for each season
    spl_data = {}
    %w[spl4 spl5 spl6 spl7 spl8 spl9 spl10].each do |spl|
      spl_data[spl] = DataAnalyzer.new.fetch_data_by_prefix(spl)
    end
    
    # Initialize categorized players hash
    @categorized_players = {
      premium: [],
      valuable: [],
      solid: [],
      supporting: []
    }
    
    @auction_players.each do |player|
      player_data = player.attributes.symbolize_keys
      
      # Add SPL data
      %w[spl4 spl5 spl6 spl7 spl8 spl9 spl10].each do |spl|
        data_source = spl_data[spl]
        
        # Batting data
        player_spl_data = data_source[:batting].find { |entry| entry[:player_name] == player_data[:name] } || {}
        player_data.merge!(
          "#{spl}_run": player_spl_data[:runs] || 0,
          "#{spl}_ball": player_spl_data[:balls] || 0,
          "#{spl}_sr": player_spl_data[:sr] || 0,
          "#{spl}_highest_score": player_spl_data[:highest_score] || 0,
          # "#{spl}_matches": player_spl_data[:matches_played] || 0,
          "#{spl}_fifties": player_spl_data[:fifties] || 0,
          "#{spl}_hundreds": player_spl_data[:hundreds] || 0,
          "#{spl}_sixes": player_spl_data[:sixes] || 0,
          "#{spl}_fours": player_spl_data[:fours] || 0
        )
        
        # Bowling data
        player_spl_data_bowling = data_source[:bowling].find { |entry| entry[:player] == player_data[:name] } || {}
        player_data.merge!(
          "#{spl}_innings": player_spl_data_bowling[:innings] || 0,
          "#{spl}_matches": player_spl_data[:matches_played] || 0,
          "#{spl}_wickets": player_spl_data_bowling[:wickets] || 0,
          "#{spl}_econ": player_spl_data_bowling[:econ] || 0,
          "#{spl}_overs": player_spl_data_bowling[:overs] || 0,
          "#{spl}_runs_given": player_spl_data_bowling[:runs_given] || 0,
          "#{spl}_maidens": player_spl_data_bowling[:maidens] || 0
        )
      end
      
      # Calculate rating using the service
      rating = PlayerRatingCalculator.calculate(player_data)
      player_data[:overall_rating] = rating
      
      case rating
      when 8.0..10.0
        @categorized_players[:premium] << player_data
      when 6.5...8.0
        @categorized_players[:valuable] << player_data
      when 5.0...6.5
        @categorized_players[:solid] << player_data
      else
        @categorized_players[:supporting] << player_data
      end
    end
    
    # Sort players within categories by rating
    @categorized_players.each do |category, players|
      players.sort_by! { |player| -player[:overall_rating] }
    end
    
    # Define categories for the view
    @categories = [
      { id: 'premium', name: 'Premium Players', color: '#ff6b35', icon: 'crown' },
      { id: 'valuable', name: 'Valuable Assets', color: '#4ecdc4', icon: 'gem' },
      { id: 'solid', name: 'Solid Performers', color: '#45b7d1', icon: 'shield-alt' },
      { id: 'supporting', name: 'Supporting Players', color: '#96ceb4', icon: 'users' }
    ]
  end

  def update_view_preference
    session[:player_view] = params[:view_type]
    head :ok
  end

  def spl_orange_cap
    @seasons = ['spl4', 'spl5', 'spl6', 'spl7', 'spl8', 'spl9', 'spl10']
    @selected_season = params[:season] || 'all'
    
    if @selected_season == 'all'
      @records = DataAnalyzer.new.fetch_combined_batting_data(*@seasons)
      @title = "All Seasons Combined"
    else
      @records = DataAnalyzer.new.fetch_combined_batting_data(@selected_season)
      @title = "#{@selected_season.upcase}"
    end
  end


  def spl_purple_cap
    @seasons = ['spl4', 'spl5', 'spl6', 'spl7', 'spl8', 'spl9', 'spl10']
    @selected_season = params[:season] || 'all'
    
    if @selected_season == 'all'
      @records = DataAnalyzer.new.fetch_combined_bowling_data(*@seasons)
      @title = "All Seasons Combined"
    else
      @records = DataAnalyzer.new.fetch_combined_bowling_data(@selected_season)
      @title = "#{@selected_season.upcase}"
    end
  end

  # def auction_list
  #   upcoming_players = AuctionPlayer.unsold
  #   @sold_players = AuctionPlayer.sold
  #   @captains = User.captains.pluck(:slug)
  #   @upcoming_players = upcoming_players.sort_by { |player| @captains.include?(player.name) ? 0 : 1 }
  # end

  def auction_list
    upcoming_players = AuctionPlayer.unsold
    @sold_players = AuctionPlayer.sold
    @captains = User.captains.pluck(:slug)
    
    @upcoming_players = upcoming_players.sort_by do |player| 
      [
        @captains.include?(player.name) ? 0 : 1,  # Captains first (0), then others (1)
        player.order || Float::INFINITY           # Then by order column (handle nil values)
      ]
    end
  end

  def auction_hotpicks
    @captains = User.captains.pluck(:username)
    @hotpicks_players = AuctionPlayer.all
  end

  private

  def generate_csv(trade_opportunities)
    CSV.generate(headers: true) do |csv|
      # Add headers
      csv << [
        'My Player', 
        'My Player Role', 
        'My Player Price',
        'Trade Range (Min)', 
        'Trade Range (Max)', 
        'Available Trade Count',
        'Trade Partner Name',
        'Trade Partner Role',
        'Trade Partner Price',
        'Trade Partner Team',
        'Trade Partner Owner'
      ]
      
      # Add data rows
      trade_opportunities.each do |opportunity|
        player = opportunity[:player]
        
        if opportunity[:possible_trades].any?
          opportunity[:possible_trades].each do |trade|
            csv << [
              player.name,
              player.role,
              format_price(opportunity[:sold_price]),
              format_price(opportunity[:price_range][:min]),
              format_price(opportunity[:price_range][:max]),
              opportunity[:trade_count],
              trade.name,
              trade.role,
              format_price(parse_price(trade.sold_price)),
              trade.owner_team_name,
              trade.owner_username
            ]
          end
        else
          # Add a row even if no trades available
          csv << [
            player.name,
            player.role,
            format_price(opportunity[:sold_price]),
            format_price(opportunity[:price_range][:min]),
            format_price(opportunity[:price_range][:max]),
            0,
            'No available trades',
            '',
            '',
            '',
            ''
          ]
        end
      end
    end
  end

  def build_trade_opportunities(my_players)
    trade_data = []
    
    my_players.each do |player|
      player_team = player.players_teams.first
      next unless player_team
      
      sold_price = parse_price(player_team.sold_price)
      next if sold_price.zero?
      
      # Calculate price range (±1 cr = ±10,000,000)
      min_price = sold_price - 10_000_000
      max_price = sold_price + 10_000_000
      
      # Ensure minimum price doesn't go below 0
      min_price = [min_price, 0].max
      
      # Find all possible trade partners
      possible_trades = find_tradeable_players(player.id, min_price, max_price)
      
      trade_data << {
        player: player,
        sold_price: sold_price,
        formatted_price: format_price(sold_price),
        price_range: {
          min: min_price,
          max: max_price,
          formatted_min: format_price(min_price),
          formatted_max: format_price(max_price)
        },
        possible_trades: possible_trades,
        trade_count: possible_trades.size
      }
    end
    
    trade_data
  end

  def find_tradeable_players(my_player_id, min_price, max_price)
    # Find all players within price range, excluding my own player and my team's players
    my_team_player_ids = current_user.teams&.first&.players&.pluck(:id)
    
    # Get all potential trade partners with proper joins
    tradeable = Player.joins("INNER JOIN players_teams ON players_teams.player_id = players.id")
      .joins("INNER JOIN teams ON players_teams.team_id = teams.id")
      .joins("INNER JOIN users ON teams.user_id = users.id")
      .where.not(id: my_team_player_ids)
      .where("players_teams.sold_price IS NOT NULL")
      .select("players.*, players_teams.sold_price, teams.team_name as owner_team_name, users.username as owner_username")
      .distinct
      .to_a # Convert to array to work with Ruby filtering
    
    # Filter by price range in Ruby (more reliable than complex SQL)
    results = tradeable.select do |player|
      next false if player.sold_price.blank? || player.sold_price.to_s.strip.empty?
      player_price = parse_price(player.sold_price)
      player_price > 0 && player_price >= min_price && player_price <= max_price
    end
    
    # Sort and limit
    results.sort_by { |p| [p.role || 2, p.name] }.first(50)
  end

  def parse_price(price_value)
    return 0 if price_value.blank?
    
    # Handle if already a number
    if price_value.is_a?(Numeric)
      return price_value.to_f
    end
    
    # Convert to string for processing
    price_string = price_value.to_s.strip
    return 0 if price_string.empty?
    
    # Remove any non-numeric characters except decimal point
    numeric_value = price_string.gsub(/[^0-9.]/, '').to_f
    
    # Check if it's in crores or lakhs
    if price_string.downcase.include?('cr')
      numeric_value * 10_000_000 # Convert crores to base unit
    elsif price_string.downcase.include?('l') || price_string.downcase.include?('lakh')
      numeric_value * 100_000 # Convert lakhs to base unit
    else
      numeric_value
    end
  end

  def format_price(price_in_base)
    if price_in_base >= 10_000_000
      "#{(price_in_base / 10_000_000.0).round(2)} Cr"
    elsif price_in_base >= 100_000
      "#{(price_in_base / 100_000.0).round(2)} L"
    else
      "#{price_in_base.to_i}"
    end
  end

  def auction_params
    params.require(:auction).permit(:name, :starts_at, :teams_count, :admin_user_id)
  end

  def auction_room_params
    params.fetch(:auction_room, {}).permit(:player_name, :amount, :amount_unit, :team_id)
  end

  def calculate_player_rating(player_data)
    total_runs = 0
    total_matches = 0
    total_sr = 0
    total_wickets = 0
    total_econ = 0
    seasons_with_data = 0
    
    %w[4 5 6 7 8].each do |spl|
      if player_data["spl#{spl}_matches".to_sym].to_i > 0
        total_runs += player_data["spl#{spl}_run".to_sym].to_i
        total_matches += player_data["spl#{spl}_matches".to_sym].to_i
        total_sr += player_data["spl#{spl}_sr".to_sym].to_f
        total_wickets += player_data["spl#{spl}_wickets".to_sym].to_i
        econ = player_data["spl#{spl}_econ".to_sym].to_f
        total_econ += econ > 0 ? econ : 0
        seasons_with_data += 1
      end
    end
    
    return 3.0 if seasons_with_data == 0
    
    seasons_with_data = [seasons_with_data, 1].max
    
    avg_runs = total_runs.to_f / seasons_with_data
    avg_sr = total_sr.to_f / seasons_with_data
    avg_wickets = total_wickets.to_f / seasons_with_data
    avg_econ = total_econ.to_f / seasons_with_data
    
    # Rating calculation
    base_points = 2.0
    runs_weight = [avg_runs / 25.0 * 4.0, 4.0].min
    
    sr_points = 0
    if avg_sr > 0
      if avg_sr >= 170
        sr_points = 1.75
      elsif avg_sr >= 140
        sr_points = 1.25
      elsif avg_sr >= 120
        sr_points = 0.75
      elsif avg_sr >= 100
        sr_points = 0.25
      end
    end
    
    wicket_points = [avg_wickets * 0.6, 2.0].min
    
    econ_points = 0
    if avg_econ > 0
      if avg_econ <= 8
        econ_points = 1.75
      elsif avg_econ <= 10
        econ_points = 1.25
      elsif avg_econ <= 12
        econ_points = 0.75
      elsif avg_econ <= 14
        econ_points = 0.25
      end
    end
    
    rating = [base_points + runs_weight + sr_points + wicket_points + econ_points, 10.0].min.round(1)
    [rating, 3.0].max
  end

  # Helper methods for the view
  def calculate_career_stats(player)
    return { avg_runs: 0, avg_sr: 0, avg_wickets: 0, avg_econ: 0 } unless player
    
    total_runs = 0
    total_sr = 0
    total_wickets = 0
    total_econ = 0
    seasons_with_data = 0
    
    %w[4 5 6 7 8 9 10].each do |spl|
      if player["spl#{spl}_matches".to_sym].to_i > 0
        total_runs += player["spl#{spl}_run".to_sym].to_i
        total_sr += player["spl#{spl}_sr".to_sym].to_f
        total_wickets += player["spl#{spl}_wickets".to_sym].to_i
        econ = player["spl#{spl}_econ".to_sym].to_f
        total_econ += econ > 0 ? econ : 0
        seasons_with_data += 1
      end
    end
    
    seasons_with_data = [seasons_with_data, 1].max
    
    {
      avg_runs: (total_runs.to_f / seasons_with_data).round(1),
      avg_sr: (total_sr.to_f / seasons_with_data).round(1),
      avg_wickets: (total_wickets.to_f / seasons_with_data).round(1),
      avg_econ: (total_econ.to_f / seasons_with_data).round(2)
    }
  end

  def calculate_seasons_played(player)
    return 0 unless player
    
    seasons_played = 0
    %w[4 5 6 7 8 9 10].each do |spl|
      # Check if overs bowled is greater than 0
      overs = player["spl#{spl}_overs".to_sym]
      seasons_played += 1 if overs.to_f > 0
    end
    seasons_played
  end
end
