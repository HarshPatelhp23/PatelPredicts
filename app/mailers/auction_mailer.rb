class AuctionMailer < ApplicationMailer
  include SkillVisualizationHelper

  def auction_summary_email
    captains = User.captains
    @teams_data = captains.map do |captain|
      {
        name: captain.franchise_name,
        captain: captain.username,
        budget_remaining: captain.remaining_purse,
        logo: Rails.root.join('app', 'assets', 'images', "#{captain.franchise_name}.png"),
        players: captain.auction_players.map do |player|
          {
            name: player.name,
            price: player.sold_price,
            batting: player.respond_to?(:batting_skill) ? player.batting_skill : rand(40..95),
            bowling: player.bowling
          }
        end
      }
    end
    
    pdf = generate_results_pdf(@teams_data)
    
    attachments['SPL-9 Teams.pdf'] = {
      mime_type: 'application/pdf',
      content: pdf
    }
    @users = Rails.application.credentials.dig(:SPLManagement, :emails)
    @users.each do |user|
      mail(to: user, subject: "SPL-9 Teams")
    end
  end

  private
  
  def generate_results_pdf(teams_data)
    pdf_content = Prawn::Document.new(page_size: "A4", margin: [30, 30, 30, 30]) do |pdf|
      # Add header with title
      pdf.font("Helvetica", size: 22, style: :bold) do
        pdf.text "SPL-9 Teams", align: :center
      end
      
      pdf.move_down 20
      
      # Add date
      pdf.font("Helvetica", size: 12) do
        pdf.text "Generated on: #{Time.now.strftime('%B %d, %Y')}", align: :right
      end
      
      pdf.move_down 30
      
      # Process each team
      teams_data.each_with_index do |team, index|
        # Team header with logo
        pdf.bounding_box([0, pdf.cursor], width: 150, height: 60) do
          # Insert team logo if available
          pdf.move_down 10
          if team[:logo].present? && File.exist?(team[:logo])
            pdf.image team[:logo], width: 50, height: 50
          else
            pdf.text "Team Logo", align: :center
          end
        end
        
        pdf.move_down 15
        # Team name and details
        pdf.bounding_box([160, pdf.cursor + 60], width: pdf.bounds.width - 160, height: 60) do
          pdf.font("Helvetica", size: 16, style: :bold) do
            pdf.text team[:name], color: "333333"
          end
          pdf.font("Helvetica", size: 12) do
            pdf.text "Owner: #{team[:captain]}"
            pdf.text "Budget Remaining: #{team[:budget_remaining]}"
          end
        end
        
        pdf.move_down 20
        
        # Create players table
        player_data = [["Player", "Price"]]
        
        team[:players].each do |player|
          player_data << [player[:name], "#{player[:price]}"]
        end
        
        pdf.table(player_data, width: pdf.bounds.width) do |t|
          t.header = true
          t.row(0).font_style = :bold
          t.row(0).background_color = "4472C4"
          t.row(0).text_color = "FFFFFF"
          t.cells.padding = [8, 10]
          t.cells.borders = [:bottom]
          t.cells.border_width = 0.5
          t.cells.border_color = "CCCCCC"
          
          # Zebra striping for rows
          player_data.length.times do |i|
            next if i == 0 # Skip header
            t.row(i).background_color = i.even? ? "EDF2FA" : "FFFFFF"
          end
        end
        
        # Add some space between teams
        pdf.move_down 40

        pdf.stroke_color "cccccc"
        pdf.stroke_horizontal_rule
        pdf.move_down 5
        
        # Add page break if not the last team and near page bottom
        if index < teams_data.length - 1 && pdf.cursor < 150
          pdf.start_new_page
        end
      end
      
      # Add footer
      pdf.page_count.times do |i|
        pdf.go_to_page(i + 1)
        pdf.bounding_box([pdf.bounds.left, pdf.bounds.bottom + 20], width: pdf.bounds.width) do
          pdf.text "Page #{i + 1} of #{pdf.page_count}", align: :center, size: 10, color: "999999"
        end
      end
    end
    
    # Return PDF content as string
    pdf_content.render
  end
end
