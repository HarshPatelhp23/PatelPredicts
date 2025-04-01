# frozen_string_literal: true

module ApplicationHelper
  include Pagy::Frontend
  TEAM_FLAGS = {
    "India" => "🇮🇳",
    "Australia" => "🇦🇺",
    "Bangladesh" => "🇧🇩",
    "England" => "🇬🇧",
    "New Zealand" => "🇳🇿",
    "Pakistan" => "🇵🇰",
    "South Africa" => "🇿🇦",
    "Sri Lanka" => "🇱🇰",
    "Afghanistan" => "🇦🇫",
    'Chennai Super Kings' => 'csk',
    'Rajasthan Royals' => 'rr',
    'Kolkata Knight Riders' => 'kkr',
    'Sunrisers Hyderabad' => 'srh',
    'Royal Challengers Bengaluru' => 'rcb',
    'Delhi Capitals' => 'dc',
    'Punjab Kings' => 'pbks',
    'Mumbai Indians' => 'mi',
    'Gujarat Titans' => 'gt',
    'Lucknow Super Giants' => 'lsg'
  }.freeze

  def display_match_name_with_flags(match_name)
    team1, team2 = match_name.split(" vs ")
    s_team1 = match_country_code[team1] || team1
    s_team2 = match_country_code[team2] || team2
    return match_name unless team1 && team2

    team1_flag = TEAM_FLAGS[team1] || ""
    team2_flag = TEAM_FLAGS[team2] || ""

    "#{team1_flag} #{s_team1}   🆚   #{team2_flag} #{s_team2}".html_safe
    # "#{team1_flag} 🆚  #{team2_flag}".html_safe
  end

  def display_ipl_match_name(match_name)
    team1, team2 = match_name.split(" vs ")
    s_team1 = match_country_code[team1] || team1
    s_team2 = match_country_code[team2] || team2
    return match_name unless team1 && team2

    "#{s_team1}  🆚  #{s_team2}".html_safe
  end

  def display_team_flags(team)
    f_team = match_country_code.key(team)
    team_flag = TEAM_FLAGS[f_team]
    team_flag
  end

  def ipl_team_logo(team_name, min_height: false)
    filename_base = TEAM_FLAGS[team_name]
    filename_base = TEAM_FLAGS.values.select { |v| v == team_name }.join if filename_base.blank?
    return unless filename_base.present?

    # Check if the image exists in assets with either .png or .jpeg
    if min_height
      if asset_exists?("#{filename_base}.png")
        image_tag("#{filename_base}.png", alt: team_name, class: "team-logo", style: "width: 70px; height: 70px; object-fit: contain;")
      elsif asset_exists?("#{filename_base}.jpeg")
        image_tag("#{filename_base}.jpeg", alt: team_name, class: "team-logo", style: "width: 70px; height: 70px; object-fit: contain;")
      else
        "Image not found"
      end
    else
      if asset_exists?("#{filename_base}.png")
        image_tag("#{filename_base}.png", alt: team_name, class: "team-logo", style: "width: 50px; height: 50px; object-fit: contain;")
      elsif asset_exists?("#{filename_base}.jpeg")
        image_tag("#{filename_base}.jpeg", alt: team_name, class: "team-logo", style: "width: 50px; height: 50px; object-fit: contain;")
      else
        "Image not found"
      end
    end
  end

  def team_color(team_abbr)
    team_colors = {
      'CSK' => '#FFFF3C',
      'DC' => '#318CE7',
      'KKR' => '#2E0854',
      'MI' => 'rgb(0,75,141)',
      'PBKS' => '#FF033E',
      'RR' => '#EA2659',
      'RCB' => '#D2042D',
      'SRH' => '#E95420',
      'GT' => '#36454F',
      'LSG' => '#89CFF0'
    }
    
    team_colors[team_abbr] || '#FFCA28' # default color if team not found
  end

  def asset_exists?(path)
    Rails.application.assets&.find_asset(path).present? || File.exist?(Rails.root.join("app/assets/images", path))
  end

  def summray_match_flags(match)
    first_team = match.split(' vs ').first
    second_team = match.split(' vs ').last

    first_team_flag = display_team_flags(match_country_code.key(first_team))
    second_team_flag = display_team_flags(match_country_code.key(second_team_flag))
    "#{first_team_flag} 🆚  #{second_team_flag}".html_safe
  end

  def add_tag(tag)
    case tag
    when 'NA'
      '<span class="badge  text-bg-danger">NA</span>'.html_safe
    when 'Added'
      '<span class="badge text-bg-success">Added</span>'.html_safe
    end
  end

  def set_min_count(title)
    case title
    when :WK
      1
    when :Batsman
      2
    when :"All-Rounder"
      1
    when :Bowler
      2
    end
  end

  def sort_players_by_role(players)
    players.sort_by { |player| Player.roles[player.role] }
  end

  def asset_exists?(path)
    Rails.root.join("app/assets/images/#{path}").exist?
  end

  def player_image(player)
    image_path = Rails.root.join("app/assets/images/#{player.name}.jpeg")
    if File.exist?(image_path)
      image_tag "#{player.name}.jpeg", style: "height: 100%;",  alt: player.name
    else
      image_tag "default_player_image.jpeg", class: "player-image mb-3", alt: "Default Player Image"
    end
  end

  def player_card_image(player)
    image_path = Rails.root.join("app/assets/images/#{player.name}.jpeg")
    if File.exist?(image_path)
      image_tag "#{player.name}.jpeg", class: "player-image mt-3",  alt: player.name
    else
      image_tag "default_player_image.jpeg", class: "player-image mt-3", alt: "Default Player Image"
    end
  end

  def player_team_detail_image(player)
    image_path = Rails.root.join("app/assets/images/#{player.name}.jpeg")
    if File.exist?(image_path)
      image_tag "#{player.name}.jpeg", style: "height: 100%; width: 100%;",  alt: player.name
    else
      image_tag "default_player_image.jpeg", class: "player-image mb-3", alt: "Default Player Image"
    end
  end

  def set_role(player)
    case player.role
    when 'wicket_keeper'
      image_tag 'WK.jpeg', style: "height: 30px; width: 30px;"
    when 'batsman'
      image_tag 'bat.png', style: "height: 30px; width: 30px;"
    when 'all_rounder'
      image_tag 'all_rounder.png', style: "height: 30px; width: 30px;"
    when 'bowler'
      image_tag 'bowler.png', style: "height: 30px; width: 30px;"
    else
      image_tag 'default_player_image.jpeg', style: "height: 30px; width: 30px;"
    end
  end

  # IPL
  def set_background_color(team_name)
    case team_name.downcase
    when 'csk'
      'bg-csk'
    when 'dc'
      'bg-dc'
    when 'kkr'
      'bg-kkr'
    when 'mi'
      'bg-mi'
    when 'pbks'
      'bg-pbks'
    when 'rr'
      'bg-rr'
    when 'rcb'
      'bg-rcb'
    when 'srh'
      'bg-srh'
    when 'gt'
      'bg-gt'
    when 'lsg'
      'bg-lsg'
    else
      ''
    end
  end

  # def set_background_color(team_name) # rubocop:disable Metrics/CyclomaticComplexity, Naming/AccessorMethodName, Metrics/MethodLength
  #   case team_name.downcase
  #   when 'aus'
  #     'bg-aus'
  #   when 'ind'
  #     'bg-ind'
  #   when 'sl'
  #     'bg-sl'
  #   when 'ban'
  #     'bg-ban'
  #   when 'eng'
  #     'bg-eng'
  #   when 'afg'
  #     'bg-afg'
  #   when 'pak'
  #     'bg-pak'
  #   when 'rsa'
  #     'bg-rsa'
  #   when 'wi'
  #     'bg-wi'
  #   when 'nz'
  #     'bg-nz'
  #   when 'usa'
  #     'bg-usa'
  #   when 'ca'
  #     'bg-ca'
  #   when 'ire'
  #     'bg-ire'
  #   when 'nam'
  #     'bg-nam'
  #   when 'nep'
  #     'bg-nep'
  #   when 'neth'
  #     'bg-neth'
  #   when 'ug'
  #     'bg-ug'
  #   when 'omn'
  #     'bg-omn'
  #   when 'png'
  #     'bg-png'
  #   when 'scot'
  #     'bg-scot'
  #   else
  #     ''
  #   end
  # end

  def convert_country_code(match)
    countries = match.split(' vs ')
    updated_match_name = countries.map { |country| match_country_code[country] || country }
    updated_match_name.join(' vs ')
  end

  def set_match_details(match)
    team1, team2 = match.split(" vs ")
    u_team1, u_team2 = match_country_code[team1]
    match_record = match_record = MatchSchedule.find_by(match_name: "#{match_country_code.key(team1)} vs #{match_country_code.key(team2)}") || match_record = MatchSchedule.find_by(match_name: "#{match_country_code.key(team2)} vs #{match_country_code.key(team1)}")
    return { match_date: '', match_stadium: '' } unless match_record&.match_date.present? && match_record.stadium.present?

    { match_date: match_record.match_date, match_stadium: match_record.stadium }
  end

  def match_country_code
    {
      'Chennai Super Kings' => 'CSK',
      'Rajasthan Royals' => 'RR',
      'Kolkata Knight Riders' => 'KKR',
      'Sunrisers Hyderabad' => 'SRH',
      'Royal Challengers Bengaluru' => 'RCB',
      'Delhi Capitals' => 'DC',
      'Punjab Kings' => 'PBKS',
      'Mumbai Indians' => 'MI',
      'Gujarat Titans' => 'GT',
      'Lucknow Super Giants' => 'LSG'
    }
  end

  # def match_country_code
  #   {
  #     'Afghanistan' => 'AFG',
  #     'Australia' => 'AUS',
  #     'Bangladesh' => 'BAN',
  #     'England' => 'ENG',
  #     'India' => 'IND',
  #     'New Zealand' => 'NZ',
  #     'Pakistan' => 'PAK',
  #     'South Africa' => 'RSA',
  #     'Sri Lanka' => 'SL',
  #     'West Indies' => 'WI',
  #     'USA' => 'USA',
  #     'Canada' => 'CA',
  #     'Ireland' => 'IRE',
  #     'Namibia' => 'NAM',
  #     'Nepal' => 'NEP',
  #     'Netherlands' => 'NETH',
  #     'Oman' => 'OMN',
  #     'Papua New Guinea' => 'PNG',
  #     'Scotland' => 'SCOT',
  #     'Uganda' => 'UG'
  #   }
  # end
end
