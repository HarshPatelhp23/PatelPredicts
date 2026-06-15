class AuctionMailer < ApplicationMailer
  include SkillVisualizationHelper

  SVL_TEAM_MAPPING = {
    'Yash Agrawal' => 'Shakuni_Sena',
    'Haardam Doshi' => 'Strikers',
    'Rushabh Shah' => 'Snipers',
    'Rushil Khatri' => 'Stallions'
  }.freeze

  def auction_summary_email
    captains = User.captains
    @teams_data = captains.map do |captain|
      {
        name: captain.franchise_name,
        captain: captain.username,
        budget_remaining: captain.remaining_purse,
        logo: Rails.root.join('app', 'assets', 'images', "v_sugam_#{SVL_TEAM_MAPPING[captain.username].downcase}.jpg"),
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
  
    # Add attachment BEFORE mail
    attachments['SVL-1_Teams.pdf'] = {
      mime_type: 'application/pdf',
      content: pdf
    }
    
    @users = ENV['SPL_EMAILS']&.split(',') || Rails.application.credentials.dig(:SPLManagement, :emails)
    
    @users.each do |user|
      # Use the block format for mail
      mail(to: user, subject: "SVL-1 Teams - Auction Results") do |format|
        format.html { render html: email_html_content.html_safe }
        format.text { render plain: email_text_content }
      end
    end
  end

  private
  
  def email_text_content
    <<~TEXT
      SVL-1 Auction Results
      =====================
      
      #{@teams_data.map { |team| 
        "#{team[:name]} (Captain: #{team[:captain]})\n" +
        "Budget Remaining: #{team[:budget_remaining]}\n" +
        "Players: #{team[:players].map { |p| p[:name] }.join(', ')}\n"
      }.join("\n")}
      
      Full details are attached in the PDF.
      
      ---
      Generated on: #{Time.now.strftime('%B %d, %Y at %I:%M %p')}
      SVL-1 Management
    TEXT
  end
  
  def email_html_content
    <<~HTML
      <!DOCTYPE html>
      <html>
      <head>
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          h1 { color: #1a472a; border-bottom: 2px solid #1a472a; padding-bottom: 10px; }
          .team { margin-bottom: 30px; padding: 15px; background: #f5f5f5; border-radius: 8px; }
          .team-name { font-size: 18px; font-weight: bold; color: #1a472a; }
          .captain { color: #666; margin-bottom: 10px; }
          .players { margin-left: 20px; }
          .footer { margin-top: 30px; padding-top: 10px; border-top: 1px solid #ccc; font-size: 12px; color: #999; }
        </style>
      </head>
      <body>
        <h1>🏐 SVL-1 Auction Results</h1>
        <p>Generated on: #{Time.now.strftime('%B %d, %Y at %I:%M %p')}</p>
        
        #{@teams_data.map { |team|
          <<~TEAM
            <div class="team">
              <div class="team-name">#{team[:name]}</div>
              <div class="captain">Captain: #{team[:captain]} | Budget Remaining: #{team[:budget_remaining]}</div>
              <div class="players">
                <strong>Players:</strong>
                <ul>
                  #{team[:players].map { |p| "<li>#{p[:name]} - ₹#{p[:price]}</li>" }.join}
                </ul>
              </div>
            </div>
          TEAM
        }.join}
        
        <div class="footer">
          <p>Full details with player statistics are attached in the PDF.</p>
          <p>&copy; #{Time.now.year} SVL-1 Management</p>
        </div>
      </body>
      </html>
    HTML
  end
  
  def generate_results_pdf(teams_data)
    pdf_content = Prawn::Document.new(page_size: "A4", margin: [30, 30, 30, 30]) do |pdf|
      pdf.font("Helvetica", size: 22, style: :bold) do
        pdf.text "SVL-1 Teams", align: :center
      end
      
      pdf.move_down 20
      
      pdf.font("Helvetica", size: 12) do
        pdf.text "Generated on: #{Time.now.strftime('%B %d, %Y')}", align: :right
      end
      
      pdf.move_down 30
      
      teams_data.each_with_index do |team, index|
        # Team header with logo
        pdf.bounding_box([0, pdf.cursor], width: 150, height: 60) do
          pdf.move_down 10
          if team[:logo].present? && File.exist?(team[:logo])
            pdf.image team[:logo], width: 50, height: 50
          else
            pdf.text "Team Logo", align: :center
          end
        end
        
        pdf.move_down 15
        pdf.bounding_box([160, pdf.cursor + 60], width: pdf.bounds.width - 160, height: 60) do
          pdf.font("Helvetica", size: 16, style: :bold) do
            pdf.text team[:name].to_s, color: "333333"
          end
          pdf.font("Helvetica", size: 12) do
            pdf.text "Owner: #{team[:captain]}"
            pdf.text "Budget Remaining: #{team[:budget_remaining]}"
          end
        end
        
        pdf.move_down 20
        
        player_data = [["Player", "Price (Lakhs)", "Batting", "Bowling"]]
        
        team[:players].each do |player|
          player_data << [
            player[:name].to_s,
            player[:price].to_s,
            player[:batting] || "-",
            player[:bowling] || "-"
          ]
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
          t.cells.size = 10
          
          player_data.length.times do |i|
            next if i == 0
            t.row(i).background_color = i.even? ? "EDF2FA" : "FFFFFF"
          end
        end
        
        pdf.move_down 40
        pdf.stroke_color "cccccc"
        pdf.stroke_horizontal_rule
        pdf.move_down 5
        
        if index < teams_data.length - 1 && pdf.cursor < 150
          pdf.start_new_page
        end
      end
      
      pdf.page_count.times do |i|
        pdf.go_to_page(i + 1)
        pdf.bounding_box([pdf.bounds.left, pdf.bounds.bottom + 20], width: pdf.bounds.width) do
          pdf.text "Page #{i + 1} of #{pdf.page_count}", align: :center, size: 10, color: "999999"
        end
      end
    end
    
    pdf_content.render
  end
end
