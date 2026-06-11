class WeeklyTeamReportPdf
  include Prawn::View

  def initialize(week_start, week_end)
    @week_start = week_start
    @week_end = week_end
    @users = User.includes(:teams).order(:username)
  end

  def generate
    @document = Prawn::Document.new(
      page_size: 'A4',
      margin: 40,
      page_layout: :portrait
    )

    # Add header on first page
    add_header
    
    # Add content for each user
    @users.each_with_index do |user, index|
      start_new_page
      add_user_team_section(user)
    end

    # Add footer on all pages
    add_page_numbers

    @document.render
  end

  private

  def add_header
    # Title section with background
    bounding_box([0, cursor], width: bounds.width, height: 80) do
      fill_color 'E8F4F8'
      fill_rectangle [0, 80], bounds.width, 80
      fill_color '000000'

      move_down 15
      font('Helvetica', size: 24, style: :bold) do
        text 'Patel-Predicts', align: :center, color: '1a5490'
      end
      
      move_down 5
      font('Helvetica', size: 14) do
        text "Weekly Team Report", align: :center, color: '2d3748'
      end
      
      move_down 5
      font('Helvetica', size: 11) do
        text "Week: #{@week_start.strftime('%d %b')} - #{@week_end.strftime('%d %b, %Y')}", 
             align: :center, color: '4a5568'
      end
    end

    move_down 30
  end

  def add_user_team_section(user)
    team = user.teams.first

    # User header with team name
    bounding_box([0, cursor], width: bounds.width) do
      fill_color 'F7FAFC'
      fill_rectangle [0, 50], bounds.width, 50
      fill_color '000000'

      move_down 12
      
      # Team owner and team name in same line
      font('Helvetica', size: 16, style: :bold) do
        text safe_text(user.username), color: '1a202c'
      end
      
      move_down 3
      
      if team
        font('Helvetica', size: 12) do
          text "Team: #{safe_text(team.team_name)}", color: '4a5568'
        end
      end
    end

    move_down 20

    if team && team.players.any?
      # Get playing 11 and bench players
      playing_11 = PlayersTeam.where(team:, bench: false).order(:points)
      bench_players = PlayersTeam.where(team:, bench: true).order(:points)

      # Playing 11 Section
      add_players_table("Playing 11", playing_11, '10B981')

      move_down 20

      # Bench Section
      add_players_table("Bench", bench_players, 'F59E0B')
    else
      font('Helvetica', size: 11, style: :italic) do
        text "No team created yet", color: '718096'
      end
    end

    move_down 10

    # Divider line
    stroke_color 'CBD5E0'
    stroke_horizontal_rule
    stroke_color '000000'
  end

  def add_players_table(title, players, color_code)
    # Section header
    bounding_box([0, cursor], width: 475) do
      fill_color color_code
      fill_rectangle [0, 25], 5, 25
      fill_color '000000'

      indent(15) do
        move_down 5
        font('Helvetica', size: 13, style: :bold) do
          text safe_text(title), color: '1a202c'
        end
      end
    end

    move_down 10

    if players.any?
      # Create table data
      table_data = [
        [
          { content: '#', background_color: 'F7FAFC', font_style: :bold },
          { content: 'Player Name', background_color: 'F7FAFC', font_style: :bold },
          { content: 'Role', background_color: 'F7FAFC', font_style: :bold },
          { content: 'Team', background_color: 'F7FAFC', font_style: :bold },
          { content: 'Points', background_color: 'F7FAFC', font_style: :bold }
        ]
      ]

      players.each_with_index do |players_team_record, index|
        player = players_team_record.player
        table_data << [
          (index + 1).to_s,
          safe_text(player.name),
          player.role.titleize,
          safe_text(player.team_name || '-'),
          player.players_teams.first.points.to_s
        ]
      end

      # Render table
      table(table_data, 
        width: 475,
        cell_style: { 
          padding: [8, 10],
          borders: [:bottom],
          border_color: 'E2E8F0',
          border_width: 0.5,
          size: 10
        },
        column_widths: { 
          0 => 35,   # #
          1 => 200,  # Name
          2 => 100,  # Role
          3 => 80,   # Team
          4 => 60    # Points
        }
      ) do
        # Style header row
        row(0).font_style = :bold
        row(0).borders = [:bottom]
        row(0).border_width = 1
        row(0).border_color = 'CBD5E0'

        # Alternate row colors
        rows(1..-1).each_with_index do |row, idx|
          row.background_color = idx.even? ? 'FFFFFF' : 'F7FAFC'
        end

        # Remove borders from last row
        row(-1).borders = []
      end

      # Summary row
      move_down 5
      font('Helvetica', size: 10, style: :bold) do
        text "Total Players: #{players.count}", align: :right, color: '4a5568'
      end
    else
      font('Helvetica', size: 10, style: :italic) do
        text "No players", color: '9CA3AF'
      end
    end
  end

  def add_page_numbers
    options = {
      at: [bounds.right - 100, 0],
      width: 100,
      align: :right,
      start_count_at: 1,
      color: '718096',
      size: 9
    }

    number_pages "Page <page> of <total>", options
  end

  def format_currency(amount)
    # Format as Indian currency (lakhs/crores)
    return '0' if amount.nil? || amount.zero?
    
    if amount >= 10000000
      "#{(amount / 10000000.0).round(2)} Cr"
    elsif amount >= 100000
      "#{(amount / 100000.0).round(2)} L"
    else
      amount.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
    end
  end

  # Sanitize text to ensure Windows-1252 compatibility
  def safe_text(text)
    return '' if text.nil?
    
    # Convert to string and remove any characters that aren't Windows-1252 compatible
    text.to_s.encode('Windows-1252', invalid: :replace, undef: :replace, replace: '?')
  rescue Encoding::InvalidByteSequenceError, Encoding::UndefinedConversionError
    # Fallback: remove non-ASCII characters
    text.to_s.gsub(/[^[:ascii:]]/, '?')
  end

  def document
    @document
  end
end
