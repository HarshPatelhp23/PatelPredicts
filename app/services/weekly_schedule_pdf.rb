# app/services/weekly_schedule_pdf.rb
# Generates a compact, professional PDF with table-based layout

class WeeklySchedulePdf
  include Prawn::View

  def initialize(week_start, week_end)
    @week_start = week_start
    @week_end = week_end
    @matches = MatchSchedule.where(match_date: @week_start..@week_end)
                           .order(:match_date, :time)
  end

  def generate
    @document = Prawn::Document.new(
      page_size: 'A4',
      margin: 25,
      page_layout: :portrait
    )

    add_header
    
    if @matches.any?
      add_matches_compact
    else
      add_no_matches_message
    end

    add_page_numbers

    @document.render
  end

  private

  def add_header
    bounding_box([0, cursor], width: bounds.width, height: 60) do
      fill_color 'E8F4F8'
      fill_rectangle [0, 60], bounds.width, 60
      fill_color '000000'

      move_down 10
      font('Helvetica', size: 20, style: :bold) do
        text 'Patel-Predicts', align: :center, color: '1a5490'
      end
      
      move_down 3
      font('Helvetica', size: 11) do
        text "Weekly Schedule", align: :center, color: '2d3748'
      end
      
      move_down 3
      font('Helvetica', size: 9) do
        text "#{@week_start.strftime('%d %b')} - #{@week_end.strftime('%d %b %Y')}", 
             align: :center, color: '4a5568'
      end
    end

    move_down 15
  end

  def add_matches_compact
    @matches.each do |match|
      teams = extract_team_names(match.match_name)
      participating_players = get_participating_players(match, teams)
      
      # Only show matches where fantasy owners have players
      next unless participating_players.any?
      
      # Check if we need a new page
      estimated_height = 45 + (participating_players.count * 35)
      start_new_page if cursor < estimated_height + 50
      
      add_match_with_table(match, teams, participating_players)
      move_down 12
    end
  end

  def add_match_with_table(match, teams, participating_players)
    # Match header bar
    bounding_box([0, cursor], width: bounds.width, height: 32) do
      fill_color '1E40AF'
      fill_rectangle [0, 32], bounds.width, 32
      fill_color '000000'

      # Left team logo
      if teams.count == 2
        left_logo = get_team_logo_path(teams[0])
        if left_logo && File.exist?(left_logo)
          image left_logo, at: [8, cursor - 4], width: 24, height: 24
        end
        
        # Right team logo
        right_logo = get_team_logo_path(teams[1])
        if right_logo && File.exist?(right_logo)
          image right_logo, at: [bounds.width - 32, cursor - 4], width: 24, height: 24
        end
      end

      # Match info
      bounding_box([35, cursor], width: bounds.width - 70) do
        move_down 4
        font('Helvetica', size: 11, style: :bold) do
          text teams.join(' vs '), align: :center, color: 'FFFFFF'
        end
        
        move_down 1
        font('Helvetica', size: 7) do
          info = "#{match.match_date.strftime('%a, %d %b')}"
          info += " • #{match.time}" if match.time.present?
          info += " • #{safe_text(match.stadium)}" if match.stadium.present?
          text info, align: :center, color: 'DBEAFE'
        end
      end
    end

    move_down 35

    # Table with players
    create_players_table(participating_players)
  end

  def create_players_table(participating_players)
    table_data = []
    
    # Header
    table_data << [
      make_cell('Owner', bold: true, bg: 'F7FAFC'),
      make_cell('Playing 11', bold: true, bg: 'D1FAE5'),
      make_cell('Bench', bold: true, bg: 'FEF3C7')
    ]

    # Rows
    participating_players.each do |user, players|
      table_data << [
        format_owner_cell(user),
        format_players_cell(players[:playing11], user.teams.first),
        format_players_cell(players[:bench], user.teams.first)
      ]
    end

    table(table_data,
      width: 545,
      cell_style: {
        padding: 5,
        border_width: 0.5,
        border_color: 'E5E7EB',
        borders: [:bottom]
      },
      column_widths: { 0 => 110, 1 => 250, 2 => 185 }
    ) do
      row(0).font_style = :bold
      row(0).size = 8
      row(0).border_width = 1
      row(0).border_color = 'CBD5E0'
      row(-1).borders = []
    end
  end

  def make_cell(text, bold: false, bg: nil)
    {
      content: text,
      font_style: bold ? :bold : :normal,
      background_color: bg,
      size: 8
    }
  end

  def format_owner_cell(user)
    team_name = user.teams.first&.team_name || 'No Team'
    
    make_formatted_text([
      { text: "#{safe_text(user.username)}\n", styles: [:bold], size: 9 },
      { text: safe_text(team_name), color: '6B7280', size: 7 }
    ])
  end

  def format_players_cell(players, team)
    return make_cell('–', bg: 'F9FAFB') if players.empty?
    
    # Build player entries with images
    player_entries = players.map do |player|
      player_team_record = team.players_teams.find_by(player_id: player.id)
      points = player_team_record&.points || player.points || 0
      
      # Format: Name (ROLE • PTS)
      {
        text: "#{safe_text(player.name)} ",
        styles: [:bold],
        size: 8
      }
    end
    
    # For now, text only - adding inline images in table cells is complex
    content = players.map do |player|
      player_team_record = team.players_teams.find_by(player_id: player.id)
      points = player_team_record&.points || player.points || 0
      "#{safe_text(player.name)} (#{role_display(player.role)} • #{points})"
    end.join(', ')
    
    { content: content, size: 7 }
  end

  def make_formatted_text(entries)
    { content: '', inline_format: true }.tap do |cell|
      cell[:content] = entries.map do |entry|
        text = entry[:text]
        size = entry[:size] || 8
        color = entry[:color]
        styles = entry[:styles] || []
        
        formatted = text
        formatted = "<b>#{formatted}</b>" if styles.include?(:bold)
        formatted = "<color rgb='#{color}'>#{formatted}</color>" if color
        formatted = "<font size='#{size}'>#{formatted}</font>" if size != 8
        formatted
      end.join
    end
  end

  def get_participating_players(match, teams)
    return {} if teams.empty?
    
    match_date = match.match_date
    result = {}

    all_match_players = Player.where(team_name: teams)
    return {} if all_match_players.empty?

    Team.includes(:user, :weekly_user_teams, :players_teams).find_each do |team|
      next unless team.user
      
      weekly_team = team.weekly_user_teams
                        .where("week_start_date <= ? AND week_end_date >= ?", match_date, match_date)
                        .last
      weekly_team = team.weekly_user_teams.last if weekly_team.blank?
      next unless weekly_team

      playing11_ids = weekly_team.playing11 & all_match_players.pluck(:id)
      bench_ids = weekly_team.bench & all_match_players.pluck(:id)

      if playing11_ids.any? || bench_ids.any?
        result[team.user] = {
          playing11: Player.where(id: playing11_ids).order(:name).to_a,
          bench: Player.where(id: bench_ids).order(:name).to_a
        }
      end
    end
    result
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

  def extract_team_names(match_name)
    t1, t2 = match_name.split(' vs ')
    t1 = match_country_code[t1]
    t2 = match_country_code[t2]
    [t1, t2]
  end

  def add_no_matches_message
    move_down 50
    
    bounding_box([50, cursor], width: bounds.width - 100, height: 80) do
      fill_color 'FEF3C7'
      fill_rectangle [0, 80], bounds.width, 80
      fill_color '000000'

      move_down 25
      
      font('Helvetica', size: 13, style: :bold) do
        text "No Matches This Week", align: :center, color: '92400E'
      end
      
      move_down 8
      
      font('Helvetica', size: 9) do
        text "There are no scheduled matches for this period.", 
             align: :center, color: 'B45309'
      end
    end
  end

  def add_page_numbers
    number_pages "Page <page> of <total>",
      at: [bounds.right - 70, 0],
      width: 70,
      align: :right,
      size: 7,
      color: '718096'
  end

  def get_team_logo_path(team_code)
    return nil if team_code.blank?
    
    base_names = [
      team_code.upcase,
      team_code.downcase,
      map_team_code_to_filename(team_code)
    ].compact.uniq
    
    extensions = ['png', 'jpg', 'jpeg', 'svg']
    
    base_names.each do |base_name|
      extensions.each do |ext|
        path = Rails.root.join('app', 'assets', 'images', "#{base_name}.#{ext}")
        return path.to_s if File.exist?(path)
      end
    end
    
    nil
  end

  def map_team_code_to_filename(team_code)
    mapping = {
      'CSK' => 'csk', 'MI' => 'mi', 'RCB' => 'rcb', 'KKR' => 'kkr',
      'DC' => 'dc', 'PBKS' => 'pbks', 'RR' => 'rr', 'SRH' => 'srh',
      'GT' => 'gt', 'LSG' => 'lsg', 'IND' => 'ind', 'AUS' => 'aus',
      'ENG' => 'eng', 'PAK' => 'pak', 'NZ' => 'nz', 'RSA' => 'rsa',
      'WI' => 'wi', 'SL' => 'sl', 'AFG' => 'afg', 'BAN' => 'ban',
      'ZIM' => 'zim', 'OMA' => 'oma', 'SCO' => 'sco', 'ITA' => 'ita',
      'NEP' => 'nep', 'NAM' => 'nam', 'NED' => 'ned', 'UAE' => 'uae',
      'USA' => 'usa', 'CAN' => 'can', 'IRE' => 'ire', 'SA' => 'rsa'
    }
    
    mapping[team_code.upcase] || team_code.downcase
  end

  def role_display(role)
    case role
    when 'batsman', 0 then 'BAT'
    when 'bowler', 1 then 'BOWL'
    when 'all_rounder', 2 then 'AR'
    when 'wicket_keeper', 3 then 'WK'
    else 'UNK'
    end
  end

  def safe_text(text)
    return '' if text.nil?
    
    text.to_s.encode('Windows-1252', invalid: :replace, undef: :replace, replace: '?')
  rescue Encoding::InvalidByteSequenceError, Encoding::UndefinedConversionError
    text.to_s.gsub(/[^[:ascii:]]/, '?')
  end

  def document
    @document
  end
end
