module SkillVisualizationHelper
  # Generate skill bars for PDF documents
  def draw_skill_bar(pdf, x, y, skill_value, width: 80, height: 8)
    # Normalize skill value between 0 and 100
    skill_value = [[skill_value.to_i, 0].max, 100].min
    
    # Draw background bar
    pdf.fill_color "EEEEEE"
    pdf.fill_rounded_rectangle [x, y], width, height, 3
    
    # Calculate value width
    value_width = (skill_value.to_f / 100) * width
    
    # Determine color based on skill level
    color = case skill_value
            when 0..40 then "D32F2F"  # Red
            when 41..60 then "FF9800"  # Orange
            when 61..80 then "4CAF50"  # Green
            else "4472C4"             # Blue
            end
            
    # Draw skill value bar
    pdf.fill_color color
    pdf.fill_rounded_rectangle [x, y], value_width, height, 3
    
    # Add skill value text
    pdf.fill_color "666666"
    pdf.font_size 9
    pdf.text_box skill_value.to_s, 
                at: [x + width + 5, y + 6], 
                width: 25, 
                height: 10
                
    # Reset colors
    pdf.fill_color "000000"
  end
  
  # Create player stat cards for PDF
  def create_player_stat_card(pdf, player, x, y, width, height)
    # Card background
    pdf.fill_color "FFFFFF"
    pdf.fill_rounded_rectangle [x, y], width, height, 8
    pdf.stroke_color "D0D8E8"
    pdf.stroke_rounded_rectangle [x, y], width, height, 8
    
    # Player name
    pdf.fill_color "2B4C8A"
    pdf.font_size 12
    pdf.font_style = :bold
    pdf.text_box player[:name], 
                at: [x + 10, y - 15], 
                width: width - 20, 
                height: 15
                
    # Stat bars
    margin = 30
    pdf.font_size 10
    pdf.font_style = :normal
    
    # Batting
    pdf.fill_color "666666"
    pdf.text_box "Batting:", 
                at: [x + 10, y - margin - 5], 
                width: 45, 
                height: 10
    draw_skill_bar(pdf, x + 65, y - margin - 8, player[:batting] || 50)
    
    # Bowling
    pdf.text_box "Bowling:", 
                at: [x + 10, y - margin - 25], 
                width: 45, 
                height: 10
    draw_skill_bar(pdf, x + 65, y - margin - 28, player[:bowling] || 50)
    
    # Price
    pdf.fill_color "FF9E1B"
    pdf.font_style = :bold
    pdf.text_box "$#{player[:price]}", 
                at: [x + width - 60, y - 15], 
                width: 50, 
                height: 15,
                align: :right
                
    # Reset styles
    pdf.fill_color "000000"
    pdf.font_style = :normal
  end
  
  # Generate team roster visualization 
  def create_team_roster_visualization(pdf, team, width)
    # Calculate grid layout based on player count
    player_count = team[:players].count
    columns = [player_count, 3].min
    rows = (player_count.to_f / columns).ceil
    
    # Card dimensions
    card_width = (width - 20) / columns - 10
    card_height = 80
    
    team[:players].each_with_index do |player, index|
      # Calculate position
      col = index % columns
      row = index / columns
      
      x = 10 + col * (card_width + 10)
      y = pdf.cursor - row * (card_height + 10)
      
      # Draw card
      create_player_stat_card(pdf, player, x, y, card_width, card_height)
    end
    
    # Return the new cursor position
    pdf.cursor - rows * (card_height + 10) - 10
  end
  
  # Create star rating visual
  def star_rating(value)
    # Convert numerical value to stars
    value = value.to_i
    full_stars = value / 20
    half_star = (value % 20) >= 10 ? 1 : 0
    empty_stars = 5 - full_stars - half_star
    
    "★" * full_stars + (half_star == 1 ? "½" : "") + "☆" * empty_stars
  end
  
  # Generate radar chart for player stats
  def create_player_radar_chart(pdf, player, x, y, size)
    # Define center and radius
    cx = x + size/2
    cy = y - size/2
    radius = size/2 - 10
    
    # Define stats and normalize between 0-1
    batting = (player[:batting] || 50).to_f / 100
    bowling = (player[:bowling] || 50).to_f / 100
    
    # Calculate additional stats for a more interesting radar chart
    fielding = rand(40..95).to_f / 100  # Random fielding stat
    experience = rand(40..95).to_f / 100  # Random experience stat
    fitness = rand(40..95).to_f / 100  # Random fitness stat
    
    # Define skill points (5 dimensions)
    skills = [batting, bowling, fielding, experience, fitness]
    points = []
    
    # Plot points on the chart
    5.times do |i|
      angle = 2 * Math::PI * (i.to_f / 5) - Math::PI / 2
      r = radius * skills[i]
      points << [cx + r * Math.cos(angle), cy + r * Math.sin(angle)]
    end
    
    # Draw background pentagon
    background_points = []
    5.times do |i|
      angle = 2 * Math::PI * (i.to_f / 5) - Math::PI / 2
      background_points << [cx + radius * Math.cos(angle), cy + radius * Math.sin(angle)]
    end
    
    # Draw axes
    pdf.stroke_color "CCCCCC"
    pdf.line_width = 0.5
    5.times do |i|
      angle = 2 * Math::PI * (i.to_f / 5) - Math::PI / 2
      pdf.stroke_line cx, cy, cx + radius * Math.cos(angle), cy + radius * Math.sin(angle)
    end
    
    # Draw radar background
    pdf.stroke_color "CCCCCC"
    pdf.fill_color "EEEEEE"
    pdf.fill_polygon *background_points.flatten
    pdf.stroke_polygon *background_points.flatten
    
    # Draw radar chart
    pdf.stroke_color "4472C4"
    pdf.fill_color "4472C4"
    pdf.fill_and_stroke_polygon *points.flatten, fill_opacity: 0.3
    
    # Add labels
    labels = ["Batting", "Bowling", "Fielding", "Experience", "Fitness"]
    pdf.fill_color "666666"
    pdf.font_size 8
    
    5.times do |i|
      angle = 2 * Math::PI * (i.to_f / 5) - Math::PI / 2
      label_x = cx + (radius + 15) * Math.cos(angle)
      label_y = cy + (radius + 15) * Math.sin(angle)
      
      # Adjust text alignment based on position
      align = :center
      align = :left if angle > Math::PI / 2 && angle < 3 * Math::PI / 2
      align = :right if angle > 3 * Math::PI / 2 || angle < Math::PI / 2
      
      pdf.text_box labels[i], 
                  at: [label_x - 20, label_y + 5], 
                  width: 40, 
                  height: 10,
                  align: align
    end
    
    # Reset colors
    pdf.fill_color "000000"
    pdf.stroke_color "000000"
  end
  
  # Create summary table of team statistics
  def create_team_summary_table(pdf, team)
    # Extract relevant stats
    total_players = team[:players].count
    avg_batting = team[:players].sum { |p| p[:batting] || 50 }.to_f / total_players
    avg_bowling = team[:players].sum { |p| p[:bowling] || 50 }.to_f / total_players
    total_spent = team[:players].sum { |p| p[:price].to_i }
    max_price = team[:players].map { |p| p[:price].to_i }.max
    
    # Create summary table
    data = [
      ["Total Players", total_players.to_s],
      ["Avg. Batting", "#{avg_batting.round(1)} / 100"],
      ["Avg. Bowling", "#{avg_bowling.round(1)} / 100"],
      ["Total Spent", "$#{total_spent}"],
      ["Max Player Price", "$#{max_price}"],
      ["Budget Remaining", "$#{team[:budget_remaining]}"]
    ]
    
    pdf.table(data, width: pdf.bounds.width / 2.5, position: :right) do |t|
      t.cells.padding = [5, 10]
      t.cells.borders = []
      t.column(0).font_style = :bold
      t.column(0).text_color = "4472C4"
      t.column(1).align = :right
      
      t.before_rendering_page do |page|
        page.row(data.length - 1).text_color = "FF9E1B"
        page.row(data.length - 1).column(1).font_style = :bold
      end
    end
  end
end
