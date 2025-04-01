# frozen_string_literal: true

class AuctionsController < ApplicationController
  def show
    @auction = Auction.find(params[:id])
  end

  def new
    @auction = Auction.new
  end

  def create
    @auction = Auction.create(auction_params)
  end

  def auction_table
    users = User.captains.sort_by { |user| TeamSkillEvaluator.calculate_winning_chances(user) }
    @users = users.sort_by { |user| TeamSkillEvaluator.calculate_winning_chances(user) }.reverse
    # @users = User.limit(4) # Fetch first 4 users
    # @user_1, @user_2, @user_3, @user_4 = @users
    @auction_rooms = AuctionRoom.all
    flash.now[:notice] = 'Welcome to SPL-7 AuctionRoom'
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

  def spl_insights
    @auction_players = AuctionPlayer.all

    # Fetch SPL data for each season
    spl4_data = DataAnalyzer.new.fetch_data_by_prefix('spl4')
    spl5_data = DataAnalyzer.new.fetch_data_by_prefix('spl5')
    spl6_data = DataAnalyzer.new.fetch_data_by_prefix('spl6')
    spl7_data = DataAnalyzer.new.fetch_data_by_prefix('spl7')

    # Merge SPL data into @auction_players
    @auction_players = @auction_players.map do |player|
      # Initialize player hash
      player_data = player.attributes.symbolize_keys

      # Add SPL-4, SPL-5, SPL-6, SPL-7 data
      %w[spl4 spl5 spl6 spl7].each do |spl|
        data_source = eval("#{spl}_data")

        # Find the player data by matching player name (case-sensitive)
        player_spl_data = data_source[:batting].find { |entry| entry[:player_name] == player_data[:name] } || {}
        # Batting Fields - Check if player_spl_data is empty, if so assign '-'
        player_data.merge!(
          "#{spl}_run": player_spl_data[:runs] || '-',
          "#{spl}_ball": player_spl_data[:balls] || '-',
          "#{spl}_sr": player_spl_data[:sr] || '-',
          "#{spl}_highest_score": player_spl_data[:highest_score] || '-',
          "#{spl}_matches": player_spl_data[:matches_played] || '-',
          "#{spl}_fifties": player_spl_data[:fifties] || '-',
          "#{spl}_hundreds": player_spl_data[:hundreds] || '-',
          "#{spl}_sixes": player_spl_data[:sixes] || '-',
          "#{spl}_fours": player_spl_data[:fours] || '-'
        )

        # Bowling Fields - Check if player_spl_data is empty, if so assign '-'
        player_spl_data_bowling = data_source[:bowling].find { |entry| entry[:player] == player_data[:name] } || {}
        player_data.merge!(
          "#{spl}_innings": player_spl_data_bowling[:innings] || '-',
          "#{spl}_wickets": player_spl_data_bowling[:wickets] || '-',
          "#{spl}_econ": player_spl_data_bowling[:econ] || '-',
          "#{spl}_overs": player_spl_data_bowling[:overs] || '-',
          "#{spl}_runs_given": player_spl_data_bowling[:runs_given] || '-',
          "#{spl}_maidens": player_spl_data_bowling[:maidens] || '-'
        )
      end

      player_data
    end
  end

  def spl_orange_cap
    @records = DataAnalyzer.new.fetch_combined_batting_data('spl4', 'spl5', 'spl6', 'spl7')
  end

  def spl_purple_cap
    @records = DataAnalyzer.new.fetch_combined_bowling_data('spl4', 'spl5', 'spl6', 'spl7')
  end

  def auction_list
    upcoming_players = AuctionPlayer.unsold
    @sold_players = AuctionPlayer.sold
    @captains = User.captains.pluck(:slug)
    @upcoming_players = upcoming_players.sort_by { |player| @captains.include?(player.name) ? 0 : 1 }
  end

  def auction_hotpicks
    @captains = User.captains.pluck(:slug)
    @hotpicks_players = AuctionPlayer.where.not(name: @captains)
  end

  private

  def auction_params
    params.require(:auction).permit(:name, :starts_at, :teams_count, :admin_user_id)
  end

  def auction_room_params
    params.fetch(:auction_room, {}).permit(:player_name, :amount, :amount_unit, :team_id)
  end
end
