# frozen_string_literal: true

namespace :players do
  desc "Import players and associate them with teams"
  task import: :environment do
    file_path = Rails.root.join('lib', 'ImportData', 'worldcup.players.json')
    
    unless File.exist?(file_path)
      puts "File not found: #{file_path}"
      next
    end

    data = JSON.parse(File.read(file_path))
    
    role_mapping = {
      "Wicket-Keeper" => :wicket_keeper,
      "Batter" => :batsman,
      "All-Rounder" => :all_rounder,
      "Bowler" => :bowler
    }

    team_mapping = {
      "India" => "IND", "Australia" => "AUS", "Bangladesh" => "BANG", "England" => "ENG", "New Zealand" => "NZ", 
      "Pakistan" => "PAK", "South Africa" => "SA", "Afghanistan" => "AFG",
    }

    data.each do |player_data|
      player_name = player_data["playerName"]
      team_name = team_mapping[player_data["country"]]
      puts "+++++++++++++ TEAM NOT FOUND FOR PLAYER:- #{player_name}" if team_name.blank?
      next if team_name.blank?

      role = role_mapping[player_data["playerType"]]
      current_team_email = player_data["currentTeam"]
      sold_price = player_data['sellingPrice']
      next if current_team_email.blank? || role.nil?

      # Find or create player
      player = Player.find_or_create_by(name: player_name) do |p|
        p.team_name = team_name
        p.role = role
      end

      # Find team by associated user email
      team = User.find_by(email: current_team_email)&.teams&.first
      if team
        # Associate player with team in join table
        players_team = PlayersTeam.create(player_id: player.id, team_id: team.id, sold_price:)
        players_team.save!
      else
        puts "No team found for #{player_name} with email: #{current_team_email}"
      end
    end

    puts "Total #{Player.count} Players imported successfully!"
  end

  task missing_images: :environment do
    missing_players_count = []
    missing_players = Player.all.select do |player|
      image_path = Rails.root.join("app/assets/images/#{player.name}.jpeg")
      !File.exist?(image_path)
    end

    if missing_players.any?
      # puts "Players without images:"
      missing_players.each { |player| puts "- #{player.name}"; missing_players_count << player }
      puts "+++++++++++++++++++++++++++++="
      puts "+++++++++++++++++++++++++++++="
      puts "TOTAL MISSING PLAYERS:- #{missing_players_count.count}"
      puts "+++++++++++++++++++++++++++++="
      puts "+++++++++++++++++++++++++++++="
    else
      puts "All players have images."
    end
  end

  task harsh_team: :environment do
    harsh_team = Team.find_by(team_name: 'Harsh Patel')
    players_prices = {
      "Shreyas Iyer" => 13.75,
      "Arshdeep Singh" => 5.75,
      "Mushfiqur Rahim" => 1,
      "Mustafizur Rahman" => 4.50,
      "Nasum Ahmed" => 1.75,
      "Tanzim Hasan Sakib" => 1,
      "Michael Bracewell" => 5.50,
      "Kane Williamson" => 14.25,
      "Will Young" => 4,
      "Mohammad Rizwan" => 16.25,
      "Salman Ali Agha" => 7.25,
      "Ben Duckett" => 11.5,
      "Adil Rashid" => 9.25,
      "Tabraiz Shamsi" => 4.25
    }
    players_prices.each do |player, sold_price|
      player_record = Player.find_or_initialize_by(name: player)
      puts "++++++++++ PLAYER:- #{player} NOT FOUND" if player_record.blank?
      player_record.save if player_record.new_record?
      next if player_record.blank?

      player_team = PlayersTeam.create(player_id: player_record.id)
      player_team.update(team: harsh_team, sold_price:)
    end
    puts "++DONE , TOTAL #{harsh_team.players.count} imported!"
  end

  task harsh2_team: :environment do
    harsh2_team = Team.find_by(team_name: 'Patidar Power')
    players_prices = {
      "Rohit Sharma" => 20.25,
      "MD Mahmud Ullah" => 0.50,  # 50 L = 0.50 CR
      "Taskin Ahmed" => 3.5,
      "Lockie Ferguson" => 8.75,
      "Glenn Phillips" => 13,
      "Ibrahim Zadran" => 7.75,
      "Rahmanullah Gurbaz" => 8.50,
      "Gulbadin Naib" => 5,
      "Jacob Bethell" => 8,
      "Harry Brook" => 9.75,
      "Pat Cummins" => 3,
      "Aiden Markram" => 12
    }
    players_prices.each do |player, sold_price|
      player_record = Player.find_or_initialize_by(name: player)
      puts "++++++++++ PLAYER:- #{player} NOT FOUND" if player_record.blank?
      player_record.save if player_record.new_record?
      next if player_record.blank?

      player_team = PlayersTeam.create(player_id: player_record.id)
      player_team.update(team: harsh2_team, sold_price:)
    end
    puts "++DONE , TOTAL #{harsh2_team.players.count} imported!"
  end

  task nisarg_team: :environment do
    nisarg_team = Team.find_by(team_name: 'Nisarg')
    players_prices = {
      "Mehidy Hasan Miraz" => 9,
      "Rachin Ravindra" => 9.25,
      "Ben Sears" => 0.50,  # 50 L = 0.50 CR
      "Saud Shakeel" => 4.45,
      "Tayyab Tahir" => 0.80,  # 80 L = 0.80 CR
      "Khushdil Shah" => 0.50,  # 50 L = 0.50 CR
      "Haris Rauf" => 10,
      "Shaheen Shah Afridi" => 11,
      "Jos Buttler" => 14,
      "Jofra Archer" => 11,
      "Jamie Smith" => 1.5,
      "Steve Smith" => 10,
      "Marco Jansen" => 12.75,
      "Tristan Stubbs" => 10
    }
    players_prices.each do |player, sold_price|
      player_record = Player.find_or_initialize_by(name: player)
      puts "++++++++++ PLAYER:- #{player} NOT FOUND" if player_record.blank?
      player_record.save if player_record.new_record?
      next if player_record.blank?

      player_team = PlayersTeam.create(player_id: player_record.id)
      player_team.update(team: nisarg_team, sold_price:)
    end
    puts "++DONE , TOTAL #{nisarg_team.players.count} imported!"
  end

  task nisarg2_team: :environment do
    nisarg2_team = Team.find_by(team_name: 'Nisarg 2')
    players_prices = {
      "KL Rahul" => 11.50,
      "Washington Sundar" => 2,
      "Jasprit Bumrah" => 8,
      "Devon Conway" => 13,
      "Will O’Rourke" => 0.75,  # 75 L = 0.75 CR
      "Kamran Ghulam" => 6,
      "Naseem Shah" => 8,
      "Fazalhaq Farooqi" => 7.5,
      "Liam Livingstone" => 8,
      "Joe Root" => 11,
      "Saqib Mahmood" => 5,
      "Josh Hazlewood" => 6.25,
      "Tony de Zorzi" => 3,
      "Lungi Ngidi" => 5,
      "Mitchell Marsh" => 3
    }
    players_prices.each do |player, sold_price|
      player_record = Player.find_or_initialize_by(name: player)
      puts "++++++++++ PLAYER:- #{player} NOT FOUND" if player_record.blank?
      player_record.save if player_record.new_record?
      next if player_record.blank?

      player_team = PlayersTeam.create(player_id: player_record.id)
      player_team.update(team: nisarg2_team, sold_price:)
    end
    puts "++DONE , TOTAL #{nisarg2_team.players.count} imported!"
  end

  task vraj_team: :environment do
    vraj_team = Team.find_by(team_name: 'Vking')
    players_prices = {
      "Marnus Labuschagne" => 10.25,
      "Kagiso Rabada" => 9,
      "Axar Patel" => 11.75,
      "Phil Salt" => 15,
      "Virat Kohli" => 24.25,
      "Nazmul Hossain Shanto" => 0.50,  # 50 L = 0.50 CR
      "Rishad Hossain" => 0.50,  # 50 L = 0.50 CR
      "Tom Latham" => 1.25,
      "Nathan Smith" => 0.50,  # 50 L = 0.50 CR
      "Usman Khan" => 0.50,  # 50 L = 0.50 CR
      "Rahmat Shah" => 0.50,  # 50 L = 0.50 CR
      "Rashid Khan" => 12.75,
      "Aaron Hardie" => 0.50,  # 50 L = 0.50 CR
      "Mitchell Starc" => 8.75,
      "Jamie Overton" => 0.50  # 50 L = 0.50 CR
    }
    players_prices.each do |player, sold_price|
      player_record = Player.find_or_initialize_by(name: player)
      puts "++++++++++ PLAYER:- #{player} NOT FOUND" if player_record.blank?
      player_record.save if player_record.new_record?
      next if player_record.blank?

      player_team = PlayersTeam.create(player_id: player_record.id)
      player_team.update(team: vraj_team, sold_price:)
    end
    puts "++DONE , TOTAL #{vraj_team.players.count} imported!"
  end

  task parth_team: :environment do
    parth_team = Team.find_by(team_name: 'Parth')
    players_prices = {
      "Hardik Pandya" => 17.75,
      "Mohammad Shami" => 11.25,
      "Jaker Ali Anik" => 0.55,  # 55 L = 0.55 CR
      "Daryl Mitchell" => 14,
      "Fakhar Zaman" => 11.25,
      "Abrar Ahmed" => 0.75,  # 75 L = 0.75 CR
      "Brydon Carse" => 0.50,  # 50 L = 0.50 CR
      "Mark Wood" => 8,
      "Nathan Ellis" => 2,
      "Josh Inglis" => 7.20,
      "Marcus Stoinis" => 1,
      "Keshav Maharaj" => 7,
      "Ryan Rickelton" => 3.50,
      "Rassie van der Dussen" => 15.25
    }
    players_prices.each do |player, sold_price|
      player_record = Player.find_or_initialize_by(name: player)
      puts "++++++++++ PLAYER:- #{player} NOT FOUND" if player_record.blank?
      player_record.save if player_record.new_record?
      next if player_record.blank?

      player_team = PlayersTeam.create(player_id: player_record.id)
      player_team.update(team: parth_team, sold_price:)
    end
    puts "++DONE , TOTAL #{parth_team.players.count} imported!"
  end

  task rushabh_team: :environment do
    rushabh_team = Team.find_by(team_name: 'rushabhdaxini9429069318@gmail.com')
    players_prices = {
      "Yashasvi Jaiswal" => 7.25,
      "Rishabh Pant" => 6.25,
      "Soumya Sarkar" => 3.25,
      "Mitchell Santner" => 10.25,
      "Matt Henry" => 8.50,
      "Faheem Ashraf" => 0.50,  # 50 L = 0.50 CR
      "Mohammad Hasnain" => 0.50,  # 50 L = 0.50 CR
      "Hashmatullah Shahidi" => 5.5,
      "Ikram Alikhil" => 0.50,  # 50 L = 0.50 CR
      "Mohammad Nabi" => 3,
      "Travis Head" => 17.5,
      "Glenn Maxwell" => 19.25,
      "Temba Bavuma" => 9,
      "David Miller" => 8.5
    }
    players_prices.each do |player, sold_price|
      player_record = Player.find_or_initialize_by(name: player)
      puts "++++++++++ PLAYER:- #{player} NOT FOUND" if player_record.blank?
      player_record.save if player_record.new_record?
      next if player_record.blank?

      player_team = PlayersTeam.create(player_id: player_record.id)
      player_team.update(team: rushabh_team, sold_price:)
    end
    puts "++DONE , TOTAL #{rushabh_team.players.count} imported!"
  end

  task devarsh_team: :environment do
    devarsh_team = Team.find_by(team_name: 'Eahhhhh')
    players_prices = {
      "Shubman Gill" => 18.50,
      "Kuldeep Yadav" => 9.50,
      "Ravindra Jadeja" => 4,
      "Tanzid Hasan" => 3,
      "Tawhid Hridoy" => 0.50,  # 50 L = 0.50 CR
      "Mark Chapman" => 1,
      "Babar Azam" => 13,
      "Azmatullah Omarzai" => 5.25,
      "Noor Ahmad" => 4.25,
      "Gus Atkinson" => 1,
      "Alex Carey" => 4.25,
      "Matt Short" => 0.50,  # 50 L = 0.50 CR
      "Adam Zampa" => 8.75,
      "Heinrich Klaasen" => 18.0,
      "Anrich Nortje" => 7.50
    }
    players_prices.each do |player, sold_price|
      player_record = Player.find_or_initialize_by(name: player)
      puts "++++++++++ PLAYER:- #{player} NOT FOUND" if player_record.blank?
      player_record.save if player_record.new_record?
      next if player_record.blank?

      player_team = PlayersTeam.create(player_id: player_record.id)
      player_team.update(team: devarsh_team, sold_price:)
    end
    puts "++DONE , TOTAL #{devarsh_team.players.count} imported!"
  end

  task missing_images: :environment do
    missing_players = []
    image_path = Rails.root.join("app/assets/images")
    
    Player.find_each do |player|
      image_file = image_path.join("#{player.name}.jpeg")
      unless File.exist?(image_file)
        missing_players << player.name
      end
    end
    
    if missing_players.any?
      puts "Players with missing images:"
      missing_players.each { |name| puts name }
    else
      puts "All player images are present."
    end
  end

  # task import_sugam_auction_data: :environment do
  #   nisarg_team = User.find_by(email: 'nisargtrivedi542@gmail.com').first.teams.first
  #   nisarg2_team = User.find_by(email: 'nisargtrivedi1910@gmail.com').first.teams.first
  #   rushabh_team = User.find_by(email: 'rushabhdaxini9429069318@gmail.com').first.teams.first
  #   parth_team = User.find_by(email: 'parthgandhi782@gmail.com').first.teams.first
  #   devarsh_team = User.find_by(email: 'anonymousman633@gmail.com').first.teams.first
  #   vraj_team = User.find_by(email: 'patelvraj308@gmail.com').first.teams.first
  #   harsh_team = Team.find_by(team_name: 'Harsh Patel').first
  #   harsh2_team = Team.find_by(team_name: 'Patidar Power').first
  #   all_teams = [nisarg_team, nisarg2_team, rushabh_team, parth_team, devarsh_team, vraj_team, harsh_team, harsh2_team]
  # end

  desc 'TODO'
  task update_points: :environment do
    Player.where(points: 0).find_each(batch_size: 100) do |player|
      points = Match.where(player:).pluck(:points)&.sum
      player.update_columns(points:)
      puts "Player - #{player.name} updated successfully"
    end
  end
  puts 'Done!'

  task update_weekly_user_teams: :environment do
    User.find_each do |user|
      playing11 = user.team.players.where(bench: true).pluck(:id)
      bench = user.team.players.where(bench: false).pluck(:id)

      user.weekly_user_teams.create(week_start_date: Date.new(204, 2, 26), week_end_date: Date.new(2024, 3, 3),
                                    playing11:, bench:)
    end
    puts 'Done!'
  end

  task update_slugs: :environment do
    User.find_each(&:save)
    Team.find_each(&:save)
    puts '++++++++++++++++++++++++++++++++++++++++++++'
    puts '++++++++++++++++++++++++++++++++++++++++++++'
    puts '++++++++++++++++++++++++++++++++++++++++++++'
    puts '++++++++++++++++++++++++++++++++++++++++++++'
    puts '++++++++++++++++++++++++++++++++++++++++++++'
    puts '++++++++++++++++++++++++++++++++++++++++++++'
    puts '++++++++++++++++++++++++++++++++++++++++++++'
    puts "Total Updated User Record:-#{User.where.not(slug: nil).count}"
    puts "Total Updated Team Records:-#{Team.where.not(slug: nil).count}"
    puts '++++++++++++++++++++++++++++++++++++++++++++'
    puts '++++++++++++++++++++++++++++++++++++++++++++'
    puts '++++++++++++++++++++++++++++++++++++++++++++'
    puts '++++++++++++++++++++++++++++++++++++++++++++'
    puts '++++++++++++++++++++++++++++++++++++++++++++'
    puts '++++++++++++++++++++++++++++++++++++++++++++'
    puts '++++++++++++++++++++++++++++++++++++++++++++'
  end

  task recorrect_user_weekly_teams: :environment do
    WeeklyUserTeam.update_all(week_end_date: Date.parse('2024-03-24'))
    puts '++++++++++++++++++++++++++++++++++++'
    puts '++++++++++++++++++++++++++++++++++++'
    puts '++++++++++++++++++++++++++++++++++++'
    puts '++++++++++++++++++++++++++++++++++++'
    puts '++++++++++++++++++++++++++++++++++++'
    puts '++++++++++++++++++++++++++++++++++++'
    puts "Total updated Records:- #{WeeklyUserTeam.where(week_end_date: Date.parse('2024-03-24')).count}"
    User.find_each do |u|
      next if u.weekly_user_teams.blank?

      puts '++++++++++++++++++++++++++++'
      puts '++++++++++++++++++++++++++++'
      puts '++++++++++++++++++++++++++++'
      puts '++++++++++++++++++++++++++++'
      puts '++++++++++++++++++++++++++++'
      puts '++++++++++++++++++++++++++++'
      puts "#{u.username}:- #{u.weekly_user_teams.first.week_end_date}"
      puts '++++++++++++++++++++++++++++'
      puts '++++++++++++++++++++++++++++'
      puts '++++++++++++++++++++++++++++'
      puts '++++++++++++++++++++++++++++'
      puts '++++++++++++++++++++++++++++'
      puts '++++++++++++++++++++++++++++'
    end
  end

  task reupdate_nt_vp_team: :environment do
    WeeklyUserTeam.where(id: [44, 45]).update_all(week_start_date: Date.new(2024, 6, 17),
                                                  week_end_date: Date.new(
                                                    2024, 6, 20
                                                  ))
    puts '+++++++++++++++++++++++++++++++++++++++++++++++++++'
    puts '+++++++++++++++++++++++++++++++++++++++++++++++++++'
    puts '+++++++++++++++++++++++++++++++++++++++++++++++++++'
    puts '+++++++++++++++++++++++++++++++++++++++++++++++++++'
    puts '++++++++++++++++++++  DONE  ++++++++++++++++++++++++++++++'
    puts '+++++++++++++++++++++++++++++++++++++++++++++++++++'
    puts '+++++++++++++++++++++++++++++++++++++++++++++++++++'
    puts '+++++++++++++++++++++++++++++++++++++++++++++++++++'
  end

  task updates_notes: :environment do
    captains = User.captains.pluck(:username) # Fetch captains
    players = AuctionPlayer.where.not(name: captains).where(note: nil) # Fetch players excluding captains

    used_notes = [] # Array to track the notes already used

    players.each do |player|
      # Generate a base note based on skill (you can modify this part)
      note = player.generate_note

      attempts = 0 # Counter to prevent infinite loops
      # Ensure the note is unique for this player
      while used_notes.include?(note) && attempts < 10
        note = player.generate_note # Re-generate the note if it has been used before
        attempts += 1
      end

      if attempts >= 10
        puts "Failed to generate a unique note for player #{player.name} after 10 attempts."
        next
      end

      # Add the note to the used notes list
      used_notes << note

      # Update the player's note
      player.update(note:)

      puts "Updated note for player: #{player.name}"  # Optional, for logging
    end
  end
end
