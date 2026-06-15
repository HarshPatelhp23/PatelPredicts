# frozen_string_literal: true

module ApplicationHelper
  include Pagy::Frontend

  TEAM_COLORS = %w[
    #e85d04 #f48c06 #06d6a0 #118ab2
    #ef476f #7209b7 #4361ee #3a0ca3
    #06d6a0 #ffd166 #118ab2 #073b4c
  ]

  SPL_TEAM_MAPPING = {
    'Haardam Doshi' => 'Strikers',
    'Yash Agrawal' => 'Stunners',
    'Parth Gandhi' => 'Scorchers',
    'Harsh' => 'Spartans',
    'Sagar Thakkar' => 'Smashers'
  }.freeze

  SVL_TEAM_MAPPING = {
    'Yash Agrawal' => 'Shakuni_Sena',
    'Haardam Doshi' => 'Strikers',
    'Rushabh Shah' => 'Snipers',
    'Rushil Khatri' => 'Stallions'
  }.freeze

  IMAGE_EXTENSIONS = %w[.png .jpg .jpeg .gif .webp].freeze


  TEAM_FLAGS = {
    # Existing flags
    "IND" => "🇮🇳",
    "AUS" => "🇦🇺",
    "BANG" => "🇧🇩",
    "ENG" => "🇬🇧",
    "NZ" => "🇳🇿",
    "PAK" => "🇵🇰",
    "RSA" => "🇿🇦",
    "SL" => "🇱🇰",
    "AFG" => "🇦🇫",
    
    # IPL Teams
    'Chennai Super Kings' => 'csk',
    'Rajasthan Royals' => 'rr',
    'Kolkata Knight Riders' => 'kkr',
    'Sunrisers Hyderabad' => 'srh',
    'Royal Challengers Bengaluru' => 'rcb',
    'Delhi Capitals' => 'dc',
    'Punjab Kings' => 'pbks',
    'Mumbai Indians' => 'mi',
    'Gujarat Titans' => 'gt',
    'Lucknow Super Giants' => 'lsg',
    
    # Additional T20 World Cup Teams from your schedule
    "USA" => "🇺🇸",
    "CAN" => "🇨🇦",
    "IRE" => "🇮🇪",
    "NAM" => "🇳🇦",
    "NEP" => "🇳🇵",
    "NED" => "🇳🇱",
    "ZIM" => "🇿🇼",
    "ITA" => "🇮🇹",
    "OMAN" => "🇴🇲",
    "SCO" => "🏴󠁧󠁢󠁳󠁣󠁴󠁿",  # Scotland flag
    "UAE" => "🇦🇪",
    "WI" => "🏝️",  # Using Welsh flag as closest representation
    # Note: West Indies is a cricket team representing multiple Caribbean nations
    # Alternative for West Indies could be: "🌴" (palm tree) or "🏝️" (island)
    
    # Additional common cricket nations (if needed)
    "Papua New Guinea" => "🇵🇬",
    "Uganda" => "🇺🇬",
    "Kenya" => "🇰🇪",
    "Hong Kong" => "🇭🇰",
    "Singapore" => "🇸🇬",
    "Malaysia" => "🇲🇾",
    "Bermuda" => "🇧🇲",
    "Jersey" => "🇯🇪",
    "Germany" => "🇩🇪",
    "Norway" => "🇳🇴",
    "Denmark" => "🇩🇰",
    "Portugal" => "🇵🇹"
  }.freeze

  def svl_team_image(team_name, html_options = {})
    slug = team_name.to_s.downcase.gsub(/\s+/, '_')
    
    # Try extensions in priority order
    filename = nil
    ["png", "jpg", "jpeg"].each do |ext|
      candidate = "v_#{slug}.#{ext}"
      asset_exists = asset_path(candidate).present? rescue false
      filesystem_exists = [
        Rails.root.join("app", "assets", "images", candidate),
        Rails.root.join("public", "assets", candidate)
      ].any?(&:exist?)
      
      if asset_exists && filesystem_exists
        filename = candidate
        break
      end
    end
    
    filename ? image_tag(filename, html_options) : nil
  end

  def team_initials(name); name.to_s.split(' ').map { |w| w[0] }.join.upcase.first(2); end

  def format_team_initials(name)
    name.split('Sugam ').last.first(2)
  end

  def team_color(index); TEAM_COLORS[index % TEAM_COLORS.length]; end

  def time_greeting
    hour = Time.current.hour
    if hour < 12
      "Morning"
    elsif hour < 17
      "Afternoon"
    else
      "Evening"
    end
  end

  def spl_team_name(username)
    # SPL_TEAM_MAPPING[username]
    username == 'Yash Agrawal' ? 'Shakuni Sena' : SVL_TEAM_MAPPING[username]
  end

  def format_svl_team_name(team_name)
    mapping = {
      'Sugam Shakuni Sena' => 'Shakuni Sena',
      'Sugam Strikers' => 'Strikers',
      'Sugam Snipers' => 'Snipers',
      'Sugam Stallions' => 'Stallions'
    }
    mapping[team_name]
  end

  def spl_team_logo(username)
    # team_name = SPL_TEAM_MAPPING[username].downcase
    team_name = "v_sugam_#{SVL_TEAM_MAPPING[username].downcase}"
    return unless team_name

    extensions = %w[png jpg jpeg webp svg]

    image_file = extensions.find do |ext|
      Rails.root.join("app/assets/images/#{team_name}.#{ext}").exist?
    end

    return unless image_file

    image_tag(
      "#{team_name}.#{image_file}",
      alt: team_name,
      class: "img-fluid spl-team-logo",
      style: "width: 70px; height: 70px; object-fit: contain;"
    )
  end

  def team_avatar(team, user)
    if user.profile_picture.attached?
      image_tag(user.profile_picture, class: "team-avatar-image", alt: "#{team.team_name} avatar")
    else
      content_tag(:span, team.team_name[0..1].upcase)
    end
  end

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

  def format_indian_currency(amount, include_symbol: true)
    return 'N/A' if amount.blank?
    
    amount = amount.to_i
    symbol = include_symbol ? '₹' : ''
    
    if amount >= 10000000
      crores = amount / 10000000.0
      "#{symbol}#{crores.round(2)} Cr"
    elsif amount >= 100000
      lakhs = amount / 100000.0
      "#{symbol}#{lakhs.round(2)} Lakh"
    else
      number_to_currency(amount, unit: '₹', delimiter: ',')
    end
  end

  def wc_team_logo(team_name, options = {})
    # Default options
    default_options = {
      size: :medium,           # :small, :medium, :large
      responsive: true,        # Enable responsive sizing
      class: "team-logo",      # Base CSS class
      alt: team_name,          # Alt text
      lazy: true               # Lazy loading
    }
    
    options = default_options.merge(options)
    
    # Clean the team name - remove any extra whitespace or special characters
    filename_base = team_name.to_s.strip.upcase
    
    # Map team codes to possible filename variations
    # This handles cases where you might have different naming conventions
    filename_variations = [
      filename_base,
      filename_base.downcase,
      # Add any specific mappings if needed
      case filename_base
      when 'SA' then 'rsa'  # South Africa sometimes uses RSA
      when 'UAE' then 'uae'
      when 'WI' then 'windies'  # West Indies
      when 'OMAN' then 'omn'
      else filename_base.downcase
      end
    ].uniq
    
    # Find the first existing image
    image_filename = nil
    image_ext = nil
    
    filename_variations.each do |filename|
      if asset_exists?("#{filename}.png")
        image_filename = filename
        image_ext = 'png'
        break
      elsif asset_exists?("#{filename}.jpg")
        image_filename = filename
        image_ext = 'jpg'
        break
      elsif asset_exists?("#{filename}.jpeg")
        image_filename = filename
        image_ext = 'jpeg'
        break
      elsif asset_exists?("#{filename}.svg")
        image_filename = filename
        image_ext = 'svg'
        break
      end
    end
    
    # Return placeholder if no image found
    unless image_filename
      return content_tag(:div, team_name, class: "team-logo-placeholder #{options[:class]}", 
                        style: "width: #{size_to_px(options[:size])}; height: #{size_to_px(options[:size])};")
    end
    
    # Determine size classes
    size_class = case options[:size]
                 when :small then "logo-sm"
                 when :medium then "logo-md"
                 when :large then "logo-lg"
                 else "logo-md"
                 end
    
    # Build CSS classes
    css_classes = ["team-logo", size_class, options[:class]]
    css_classes << "logo-responsive" if options[:responsive]
    
    # Image tag with responsive attributes
    image_tag(
      "#{image_filename}.#{image_ext}",
      alt: options[:alt],
      class: css_classes.join(" "),
      loading: options[:lazy] ? "lazy" : "eager",
      # Inline styles for fallback (CSS should override)
      style: "object-fit: contain; max-width: 100%; height: auto;"
    )
  end

  def point_difference(current_team, compared_team)
    current_points = current_team.grand_total - current_team.penalty_points
    compared_points = compared_team.grand_total - compared_team.penalty_points
    diff = compared_points - current_points
    
    if diff > 0
      "+#{diff}"
    elsif diff < 0
      diff.to_s # This will show negative sign automatically
    else
      "0"
    end
  end

  def relative_position(current_team, compared_team)
    current_points = current_team.grand_total - current_team.penalty_points
    compared_points = compared_team.grand_total - compared_team.penalty_points
    
    if compared_points > current_points
      "above"
    elsif compared_points < current_points
      "below"
    else
      "equal"
    end
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

  def format_currency(amount)
    CurrencyFormatter.format(amount)
  end

  def size_to_px(size)
    case size
    when :small then "30px"
    when :medium then "50px"
    when :large then "70px"
    else "50px"
    end
  end

  # def asset_exists?(path)
  #   Rails.application.assets&.find_asset(path).present? || File.exist?(Rails.root.join("app/assets/images", path))
  # end

  def asset_exists?(path)
    if Rails.env.production?
      # In production, check the manifest
      Rails.application.assets_manifest.assets[path].present?
    else
      # In development, check the file system
      Rails.root.join('app', 'assets', 'images', path).exist?
    end
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

  def player_image_url(player)
    image_path = Rails.root.join("app", "assets", "images", "#{player&.name}.jpeg")
    
    if File.exist?(image_path)
      asset_url("#{player&.name}.jpeg")
    else
      asset_url("default_player_image.jpeg")
    end
  end
  
  def player_image_tag(player)
    image_path = Rails.root.join("app", "assets", "images", "#{player&.name}.jpeg")
    
    if File.exist?(image_path)
      image_tag "#{player&.name}.jpeg", class: "player-image mb-3", alt: player.name
    else
      image_tag "default_player_image.jpeg", class: "player-image mb-3", alt: "Default Player Image"
    end
  end
  
  def team_logo_url(team_slug)
    return nil unless team_slug.present?
    
    # Check for different image extensions
    extensions = %w[.png .jpg .jpeg .svg .gif]
    
    # Try to find the logo with any extension
    extensions.each do |ext|
      logo_filename = "#{team_slug}#{ext}"
      logo_path = Rails.root.join("app", "assets", "images", logo_filename)
      
      if File.exist?(logo_path)
        return asset_url(logo_filename)
      end
    end
    original_filename = team_slug.downcase.gsub(' ', '_')
    extensions.each do |ext|
      logo_filename = "#{original_filename}#{ext}"
      logo_path = Rails.root.join("app", "assets", "images", logo_filename)
      
      if File.exist?(logo_path)
        return asset_url(logo_filename)
      else
        asset_url("default_player_image.jpeg")
      end
    end
  end

  def mobile_device?
    request.user_agent =~ /Mobile|Android|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i
  end

  def player_image(player)
    image_path = Rails.root.join("app/assets/images/#{player&.name}.jpeg")
    if File.exist?(image_path)
      image_tag "#{player&.name}.jpeg", class: "mt-3"
    else
      image_tag "default_player_image.jpeg", class: "player-image mb-3", alt: "Default Player Image"
    end
  end

  def player_card_image(player, klass: '')
    image_path = Rails.root.join("app/assets/images/#{player.name}.jpeg")
    if File.exist?(image_path)
      image_tag "#{player.name}.jpeg", class: "player-image mt-3 #{klass}",  alt: player.name
    else
      image_tag "default_player_image.jpeg", class: "player-image mt-3 #{klass}", alt: "Default Player Image"
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
      image_tag 'WK.jpeg', style: "height: 30px; width: 30px; background-color: white;"
    when 'batsman'
      image_tag 'bat.png', style: "height: 30px; width: 30px; background-color: white;"
    when 'all_rounder'
      image_tag 'all_rounder.png', style: "height: 30px; width: 30px; background-color: white;"
    when 'bowler'
      image_tag 'bowler.png', style: "height: 30px; width: 30px; background-color: white;"
    else
      image_tag 'default_player_image.jpeg', style: "height: 30px; width: 30px; background-color: white;"
    end
  end

  # IPL
  # def set_background_color(team_name)
  #   case team_name.downcase
  #   when 'csk'
  #     'bg-csk'
  #   when 'dc'
  #     'bg-dc'
  #   when 'kkr'
  #     'bg-kkr'
  #   when 'mi'
  #     'bg-mi'
  #   when 'pbks'
  #     'bg-pbks'
  #   when 'rr'
  #     'bg-rr'
  #   when 'rcb'
  #     'bg-rcb'
  #   when 'srh'
  #     'bg-srh'
  #   when 'gt'
  #     'bg-gt'
  #   when 'lsg'
  #     'bg-lsg'
  #   else
  #     ''
  #   end
  # end

  def set_background_color(team_name) # rubocop:disable Metrics/CyclomaticComplexity, Naming/AccessorMethodName, Metrics/MethodLength
    case team_name.downcase
    when 'aus'
      'bg-aus'
    when 'ind'
      'bg-ind'
    when 'sl'
      'bg-sl'
    when 'ban'
      'bg-ban'
    when 'eng'
      'bg-eng'
    when 'afg'
      'bg-afg'
    when 'pak'
      'bg-pak'
    when 'rsa'
      'bg-rsa'
    when 'wi'
      'bg-wi'
    when 'nz'
      'bg-nz'
    when 'usa'
      'bg-usa'
    when 'ca'
      'bg-ca'
    when 'ire'
      'bg-ire'
    when 'nam'
      'bg-nam'
    when 'nep'
      'bg-nep'
    when 'ned'
      'bg-neth'
    when 'ug'
      'bg-ug'
    when 'oman'
      'bg-oman'
    when 'png'
      'bg-png'
    when 'sco'
      'bg-scot'
    when 'ita'
      'bg-ita'
    when 'zim'
      'bg-zim'
    when 'uae'
      'bg-uae'
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

  def bootstrap_alert_class(flash_type)
    case flash_type.to_sym
    when :notice, :success then 'success'
    when :alert, :error, :danger then 'danger'
    when :warning then 'warning'
    when :info then 'info'
    else flash_type.to_s
    end
  end

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

  def get_tier_name(rating)
    case rating
    when 9..10 then "ELITE"
    when 8..8.9 then "EXPERT"
    when 7..7.9 then "PRO"
    when 6..6.9 then "ADVANCED"
    when 5..5.9 then "INTERMEDIATE"
    else "BEGINNER"
    end
  end

  def render_stat_card(label, value, icon, highlight = false)
    content_tag(:div, class: "stat-card #{'highlight' if highlight}") do
      concat content_tag(:i, '', class: icon)
      concat content_tag(:span, value || "N/A", class: "stat-value")
      concat content_tag(:span, label, class: "stat-label")
    end
  end

  def calculate_player_specialty(player)
    # Implement logic to determine if player is batsman, bowler, or all-rounder
    # This is a simplified example - adjust based on your data structure
    batting_avg = player[:overall_batting_rating].to_f
    bowling_avg = player[:overall_bowling_rating].to_f
    
    if batting_avg > bowling_avg + 2
      'batting'
    elsif bowling_avg > batting_avg + 2
      'bowling'
    else
      'all_rounder'
    end
  end

  def calculate_batting_performance(player)
    # Calculate batting performance percentage (0-100)
    # Adjust based on your metrics
    runs = player[:career_runs].to_i
    [runs / 5, 100].min # Simplified calculation
  end

  def calculate_bowling_performance(player)
    # Calculate bowling performance percentage (0-100)
    wickets = player[:career_wickets].to_i
    [wickets * 5, 100].min # Simplified calculation
  end

  def calculate_consistency(player)
    # Calculate consistency based on performance across seasons
    seasons_played = calculate_seasons_played(player)
    return 0 if seasons_played == 0
    
    # Simplified consistency calculation
    [seasons_played * 20, 100].min
  end

  def amount_in_crores(amount)
    amount.to_f / 10000000
  end
  
  # Amount in lakhs for display
  def amount_in_lakhs(amount)
    amount.to_f / 100000
  end
  
  # Format amount for display
  def display_amount(amount)
    if amount >= 10000000
      "₹#{amount_in_crores(amount).round(2)} Cr"
    else
      "₹#{amount_in_lakhs(amount).round(2)} L"
    end
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
