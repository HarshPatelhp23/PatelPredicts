# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
ActiveAdmin.register User do
  permit_params :id, :username, :email, :password, :password_confirmation, :confirmed_at, :grand_total, :final_total_points, :team_ids, :penalty_points, :otp_verified, :slug, :update_profile_count, :total_purse, :remaining_purse, :captain, auction_ids: []
  index do
    selectable_column
    id_column
    column :username
    column :email
    column :grand_total
    column :auctions
    column :final_total_points
    column :penalty_points
    column :update_profile_count
    column :total_purse
    column :remaining_purse
    column :slug
    actions defaults: true do |user|
      link_to 'Assign Team', assign_team_admin_user_path(user), method: :get
    end
  end

  form do |f|
    f.inputs 'User Details' do
      f.input :username
      f.input :email
      f.input :grand_total
      f.input :auctions, as: :select, collection: Auction.all.map { |auc| [auc.name, auc.id] }
      f.input :final_total_points
      f.input :penalty_points
      f.input :otp_verified
      f.input :update_profile_count
      f.input :total_purse
      f.input :remaining_purse
      f.input :captain
      f.input :slug
    end
    f.actions
  end

  member_action :assign_team, method: %i[get post] do
    @user = User.friendly.find(params[:id])
    if request.post?
      clean_string = params['user']['data'].gsub("\r\n", '').gsub!(/\s+/, ' ') if params['user']['data'].present?
      data = instance_eval(clean_string) if clean_string.present?
      if data.instance_of?(Array)
        begin
          ActiveRecord::Base.transaction do
            data.each do |player_data|
              Rails.logger.info "Processing Player: #{player_data[:player_name]} with Sold Price: #{player_data[:sold_price]}"

              p = Player.find_by(name: player_data[:player_name])
              if p.blank?
                raise StandardError, "Player:- #{player_data[:player_name]} is not Found"
              end

              sold_price = player_data[:sold_price].include?('L') ? (player_data[:sold_price].split.first.to_f / 100) : player_data[:sold_price]
              
              Rails.logger.info "Assigning Team to Player: #{player_data[:player_name]}"
              
              p.teams << @user.teams.where(team_name: params[:user][:teams])
              
              if p.players_teams.last.nil?
                raise StandardError, "PlayerTeam record missing for Player: #{player_data[:player_name]}"
              end

              p.players_teams.last.update_columns(sold_price: sold_price)
              p.save
            end
          end
          redirect_to admin_teams_path, notice: 'Team has been assigned successfully'
        rescue => e
          Rails.logger.error "Transaction Rolled Back: #{e.message}"
          redirect_to admin_teams_path, alert: "Error: #{e.message}"
        end
      else
        redirect_to assign_team_admin_user_path, notice: 'Invalid data'
      end
    end
  end

  controller do
    def show
      @user = User.friendly.find(params[:id])
    end

    def edit
      @user = User.friendly.find(params[:id])
    end

    def update
      @user = User.friendly.find(params[:id])
      if @user.update(user_params)
        redirect_to admin_user_path(@user), notice: 'User updated.'
      else
        flash[:error] = @user.errors.full_messages.join(', ')
        render :edit
      end
    end

    def destroy
      @user = User.friendly.find(params[:id])
      @user.destroy
      redirect_to admin_user_path, notice: 'User deleted successfully'
    end

    private

    def user_params
      params.require(:user).permit(:username, :email, :password, :password_confirmation, :confirmed_at,:grand_total, :final_total_points, :penalty_points, :otp_verified, :slug, :update_profile_count, auction_ids: [])
    end
  end

  filter :email
  filter :grand_total
  # filter :auctions do |auction|
  #   auction.users.pluck(:email)
  # end
end
# rubocop:enable Metrics/BlockLength

# parth,hardik = {
#   "Turner" => ["PS", "all_rounder", "PS", 63],
#   "Jason Behrendorff" => ["PS", "bowler", "PS", 44],
#   "Jacob Bethell" => ["MR", "batsman", "MR", 49],

# }

# malhar,harsh = {
#   "Mackenzie Harvey" => ["MR", "batsman", "MR", 41],
#   "Tom Rogers" => ["MR", "bowler", "MR", 109],
#   "Agar" => ["PS", "bowler", "PS", 44],
# }

# harsh,aashil = {
#   "Fergus O Neill" => ["MR", "all_rounder", "MR", 54],
#   "Finn Allen" => ["PS", "all_rounder", "PS", 60],
#   "Cooper Connolly" => ["PS", "batsman", "PS", 30]
# }

#HARSH
# [
#   { player_name: "Shimron Hetmyer", sold_price: "4.25 CR" },
#   { player_name: "Rohit Sharma", sold_price: "14.75 CR" },
#   { player_name: "Sachin Baby", sold_price: "1 CR" },
#   { player_name: "Musheer Khan", sold_price: "70 L" },
#   { player_name: "Deepak Chahar", sold_price: "7.75 CR" },
#   { player_name: "Angkrish Raghuvanshi", sold_price: "8.25 CR" },
#   { player_name: "Marcus Stoinis", sold_price: "3.75 CR" },
#   { player_name: "Akash Maharaj Singh", sold_price: "20 L" },
#   { player_name: "Nitish Kumar Reddy", sold_price: "14.50 CR" },
#   { player_name: "Eshan Malinga", sold_price: "20 L" },
#   { player_name: "KL Rahul", sold_price: "16 CR" },
#   { player_name: "Kumar Kartikeya", sold_price: "20 L" },
#   { player_name: "Aiden Markram", sold_price: "3.75 CR" },
#   { player_name: "T Natarajan", sold_price: "9 CR" },
#   { player_name: "Harshal Patel", sold_price: "4.50 CR" },
#   { player_name: "Mitchell Marsh", sold_price: "2.50 CR" },
#   { player_name: "Khaleel Ahmed", sold_price: "3.25 CR" },
#   { player_name: "Sameer Rizvi", sold_price: "1 CR" },
#   { player_name: "RS Hangargekar", sold_price: "20 L" },
#   { player_name: "Akash Madhwal", sold_price: "3.25 CR" }
# ]

#NISARG

# [
#   { player_name: "Manimaran Siddharth", sold_price: "20 L" },
#   { player_name: "Glenn Maxwell", sold_price: "7.75 CR" },
#   { player_name: "Matheesha Pathirana", sold_price: "13 CR" },
#   { player_name: "Rajat Patidar", sold_price: "10 CR" },
#   { player_name: "Suryansh Shedge", sold_price: "20 L" },
#   { player_name: "Marco Jansen", sold_price: "4 CR" },
#   { player_name: "Shivam Dube", sold_price: "14 CR" },
#   { player_name: "Naman Dhir", sold_price: "7 CR" },
#   { player_name: "Sherfane Rutherford", sold_price: "40 L" },
#   { player_name: "Arjun Tendulkar", sold_price: "1 CR" },
#   { player_name: "Prasidh Krishna", sold_price: "4 CR" },
#   { player_name: "Will Jacks", sold_price: "9 CR" },
#   { player_name: "Mitchell Santner", sold_price: "5 CR" },
#   { player_name: "Akash Deep", sold_price: "4.50 CR" },
#   { player_name: "Avesh Khan", sold_price: "5 CR" },
#   { player_name: "Andre Siddarth C", sold_price: "50 L" },
#   { player_name: "Philip Salt", sold_price: "7 CR" },
#   { player_name: "Vignesh Puthur", sold_price: "20 L" },
#   { player_name: "Vijaykumar Vyshak", sold_price: "60 L" },
#   { player_name: "Vaibhav Suryavanshi", sold_price: "1 CR" },
#   { player_name: "Matthew Breetzke", sold_price: "20 L" },
#   { player_name: "Raj Bawa", sold_price: "1 CR" },
#   { player_name: "Robin Minz", sold_price: "3 CR" }
# ]

#PARTH
# [
#   { player_name: "Manoj Bhandage", sold_price: "20 L" },
#   { player_name: "Mohsin Khan", sold_price: "7 CR" },
#   { player_name: "Sam Curran", sold_price: "1 CR" },
#   { player_name: "Yash Dayal", sold_price: "6.75 CR" },
#   { player_name: "Mohammed Shami", sold_price: "9.25 CR" },
#   { player_name: "Spencer Johnson", sold_price: "2 CR" },
#   { player_name: "Varun Chakaravarthy", sold_price: "9 CR" },
#   { player_name: "Riyan Parag", sold_price: "9 CR" },
#   { player_name: "Venkatesh Iyer", sold_price: "7.75 CR" },
#   { player_name: "Manish Pandey", sold_price: "1.50 CR" },
#   { player_name: "Sanju Samson", sold_price: "8 CR" },
#   { player_name: "Zeeshan Ansari", sold_price: "25 L" },
#   { player_name: "Sai Sudharsan", sold_price: "10 CR" },
#   { player_name: "Glenn Phillips", sold_price: "6 CR" },
#   { player_name: "Josh Inglis", sold_price: "6.25 CR" },
#   { player_name: "Simarjeet Singh", sold_price: "1 CR" },
#   { player_name: "Shahbaz Ahmed", sold_price: "6 CR" },
#   { player_name: "Abdul Samad", sold_price: "2 CR" },
#   { player_name: "Nehal Wadhera", sold_price: "6.50 CR" },
#   { player_name: "Shamar Joseph", sold_price: "20 L" }
# ]

#RD

# [
#   { player_name: "Shashank Singh", sold_price: "8.50 CR" },
#   { player_name: "Ayush Badoni", sold_price: "2.75 CR" },
#   { player_name: "Hardik Pandya", sold_price: "15.5 CR" },
#   { player_name: "Rahmanullah Gurbaz", sold_price: "3 CR" },
#   { player_name: "Yuzvendra Chahal", sold_price: "9 CR" },
#   { player_name: "Nuwan Thushara", sold_price: "50 L" },
#   { player_name: "Harpreet Brar", sold_price: "3.25 CR" },
#   { player_name: "Mujeeb Ur Rahman", sold_price: "1 CR" },
#   { player_name: "Ravisrinivasan Sai Kishore", sold_price: "3 CR" },
#   { player_name: "Suyash Sharma", sold_price: "2 CR" },
#   { player_name: "Anrich Nortje", sold_price: "1.50 CR" },
#   { player_name: "Axar Patel", sold_price: "11 CR" },
#   { player_name: "Devon Conway", sold_price: "7.25 CR" },
#   { player_name: "Ishan Kishan", sold_price: "8.50 CR" },
#   { player_name: "Prabhsimran Singh", sold_price: "7 CR" },
#   { player_name: "Faf du Plessis", sold_price: "6 CR" },
#   { player_name: "Harshit Rana", sold_price: "6 CR" },
#   { player_name: "Lockie Ferguson", sold_price: "4.25 CR" }
# ]

#DEVARSH

# [
#   { player_name: "Bevon Jacobs", sold_price: "55 L" },
#   { player_name: "Nitish Rana", sold_price: "6.50 CR" },
#   { player_name: "Manav Suthar", sold_price: "25 L" },
#   { player_name: "David Miller", sold_price: "4.75 CR" },
#   { player_name: "Priyansh Arya", sold_price: "1.75 CR" },
#   { player_name: "Rovman Powell", sold_price: "1.25 CR" },
#   { player_name: "Krunal Pandya", sold_price: "3.50 CR" },
#   { player_name: "Mitchell Starc", sold_price: "8.75 CR" },
#   { player_name: "Liam Livingstone", sold_price: "7.25 CR" },
#   { player_name: "Jaydev Unadkat", sold_price: "2.75 CR" },
#   { player_name: "Lungi Ngidi", sold_price: "5.50 CR" },
#   { player_name: "Ashwani Kumar", sold_price: "20 L" },
#   { player_name: "Anukul Roy", sold_price: "1.25 CR" },
#   { player_name: "Nicholas Pooran", sold_price: "15.50 CR" },
#   { player_name: "Shubman Gill", sold_price: "16 CR" },
#   { player_name: "Rahul Tripathi", sold_price: "7.25 CR" },
#   { player_name: "Chetan Sakariya", sold_price: "50 L" },
#   { player_name: "Ryan Rickelton", sold_price: "2.50 CR" },
#   { player_name: "Rasikh Dar Salam", sold_price: "1.50 CR" },
#   { player_name: "Yash Thakur", sold_price: "1.50 CR" },
#   { player_name: "Shahrukh Khan", sold_price: "6.50 CR" },
#   { player_name: "Swapnil Singh", sold_price: "2 CR" },
#   { player_name: "Arshad Khan", sold_price: "1.25 CR" },
#   { player_name: "Mukesh Choudhary", sold_price: "1 CR" }
# ]

#VANSH
# [
#   { player_name: "Rahul Chahar", sold_price: "5 CR" },
#   { player_name: "Adam Zampa", sold_price: "7.25 CR" },
#   { player_name: "Kamlesh Nagarkoti", sold_price: "35 L" },
#   { player_name: "Karn Sharma", sold_price: "1 CR" },
#   { player_name: "Ishant Sharma", sold_price: "3 CR" },
#   { player_name: "Arshin Kulkarni", sold_price: "50 L" },
#   { player_name: "Pat Cummins", sold_price: "9.75 CR" },
#   { player_name: "Gurjapneet Singh", sold_price: "20 L" },
#   { player_name: "Tushar Deshpande", sold_price: "2.25 CR" },
#   { player_name: "Tim David", sold_price: "4.25 CR" },
#   { player_name: "Jitesh Sharma", sold_price: "6 CR" },
#   { player_name: "Noor Ahmad", sold_price: "2.75 CR" },
#   { player_name: "Anuj Rawat", sold_price: "65 L" },
#   { player_name: "Ruturaj Gaikwad", sold_price: "18 CR" },
#   { player_name: "Rinku Singh", sold_price: "11.25 CR" },
#   { player_name: "Rachin Ravindra", sold_price: "1.50 CR" },
#   { player_name: "MS Dhoni", sold_price: "3 CR" },
#   { player_name: "Luvnith Sisodia", sold_price: "20 L" },
#   { player_name: "Ramandeep Singh", sold_price: "1.75 CR" },
#   { player_name: "Bhuvneshwar Kumar", sold_price: "8.25 CR" },
#   { player_name: "Fazalhaq Farooqi", sold_price: "1 CR" },
#   { player_name: "Quinton de Kock", sold_price: "3.75 CR" },
#   { player_name: "Vishnu Vinod", sold_price: "1 CR" }
# ]

#MALHAR

# [
#   { player_name: "Tilak Varma", sold_price: "14.50 CR" },
#   { player_name: "Shubham Dubey", sold_price: "20 L" },
#   { player_name: "Nathan Ellis", sold_price: "85 L" },
#   { player_name: "Vaibhav Arora", sold_price: "3.50 CR" },
#   { player_name: "Reece Topley", sold_price: "35 L" },
#   { player_name: "Darshan Nalkande", sold_price: "75 L" },
#   { player_name: "Yashasvi Jaiswal", sold_price: "15.75 CR" },
#   { player_name: "Shaik Rasheed", sold_price: "20 L" },
#   { player_name: "Yudhvir Singh Charak", sold_price: "35 L" },
#   { player_name: "Mohammed Siraj", sold_price: "8.25 CR" },
#   { player_name: "Dushmantha Chameera", sold_price: "35 L" },
#   { player_name: "Jofra Archer", sold_price: "5.75 CR" },
#   { player_name: "Donovan Ferreira", sold_price: "40 L" },
#   { player_name: "Mayank Markande", sold_price: "85 L" },
#   { player_name: "Kamindu Mendis", sold_price: "65 L" },
#   { player_name: "Mukesh Kumar", sold_price: "4.25 CR" },
#   { player_name: "Shreyas Gopal", sold_price: "20 L" },
#   { player_name: "Ravindra Jadeja", sold_price: "12 CR" },
#   { player_name: "Swastik Chikara", sold_price: "1 CR" },
#   { player_name: "Rishabh Pant", sold_price: "14.25 CR" },
#   { player_name: "Pyla Avinash", sold_price: "20 L" },
#   { player_name: "Suryakumar Yadav", sold_price: "15 CR" },
#   { player_name: "Romario Shepherd", sold_price: "35 L" },
#   { player_name: "Mohit Rathee", sold_price: "20 L" },
#   { player_name: "Praveen Dubey", sold_price: "20 L" }
# ]

#AARYA
# [
#   { player_name: "Azmatullah Omarzai", sold_price: "2.75 CR" },
#   { player_name: "Aniket Verma", sold_price: "25 L" },
#   { player_name: "Jasprit Bumrah", sold_price: "12.50 CR" },
#   { player_name: "Jacob Bethell", sold_price: "1.75 CR" },
#   { player_name: "Rashid Khan", sold_price: "15 CR" },
#   { player_name: "Mahipal Lomror", sold_price: "1 CR" },
#   { player_name: "Aaron Hardie", sold_price: "60 L" },
#   { player_name: "Moeen Ali", sold_price: "1 CR" },
#   { player_name: "Abhinav Manohar", sold_price: "2.75 CR" },
#   { player_name: "Jamie Overton", sold_price: "30 L" },
#   { player_name: "Ajay Jadav Mandal", sold_price: "40 L" },
#   { player_name: "Wanindu Hasaranga", sold_price: "5.50 CR" },
#   { player_name: "Vijay Shankar", sold_price: "3 CR" },
#   { player_name: "Kuldeep Sen", sold_price: "50 L" },
#   { player_name: "Washington Sundar", sold_price: "2.75 CR" },
#   { player_name: "Travis Head", sold_price: "16 CR" },
#   { player_name: "Abishek Porel", sold_price: "6.75 CR" },
#   { player_name: "Mohit Sharma", sold_price: "4 CR" },
#   { player_name: "Virat Kohli", sold_price: "22 CR" }
# ]

#VRAJ

# [
#   { player_name: "Deepak Hooda", sold_price: "3.25 CR" },
#   { player_name: "Tristan Stubbs", sold_price: "5 CR" },
#   { player_name: "Kumar Kushagra", sold_price: "1 CR" },
#   { player_name: "Kagiso Rabada", sold_price: "6.25 CR" },
#   { player_name: "Krishnan Shrijith", sold_price: "4 CR" },
#   { player_name: "Dhruv Jurel", sold_price: "3.25 CR" },
#   { player_name: "Ashok Sharma", sold_price: "20 L" },
#   { player_name: "Yuvraj Chaudhary", sold_price: "1 CR" },
#   { player_name: "Harnoor Singh", sold_price: "1 CR" },
#   { player_name: "Sunil Narine", sold_price: "10.25 CR" },
#   { player_name: "Josh Hazlewood", sold_price: "6 CR" },
#   { player_name: "Jos Buttler", sold_price: "14.50 CR" },
#   { player_name: "Abhishek Sharma", sold_price: "16 CR" },
#   { player_name: "Ravichandran Ashwin", sold_price: "2.50 CR" },
#   { player_name: "Trent Boult", sold_price: "14.25 CR" },
#   { player_name: "Jayant Yadav", sold_price: "2 CR" },
#   { player_name: "Atharva Taide", sold_price: "50 L" },
#   { player_name: "Rahul Tewatia", sold_price: "4 CR" },
#   { player_name: "Maheesh Theekshana", sold_price: "2.75 CR" },
#   { player_name: "Anshul Kamboj", sold_price: "1.75 CR" }
# ]

#RD-2

# [
#   { player_name: "Shreyas Iyer", sold_price: "15.25 CR" },
#   { player_name: "Andre Russell", sold_price: "1 CR" },
#   { player_name: "Jake Fraser-McGurk", sold_price: "6.50 CR" },
#   { player_name: "Karun Nair", sold_price: "80 L" },
#   { player_name: "Karim Janat", sold_price: "20 L" },
#   { player_name: "Mayank Yadav", sold_price: "13 CR" },
#   { player_name: "Ravi Bishnoi", sold_price: "8.25 CR" },
#   { player_name: "Heinrich Klaasen", sold_price: "14 CR" },
#   { player_name: "Gerald Coetzee", sold_price: "50 L" },
#   { player_name: "Kulwant Khejroliya", sold_price: "50 L" },
#   { player_name: "Ashutosh Sharma", sold_price: "4 CR" },
#   { player_name: "Devdutt Padikkal", sold_price: "1.25 CR" },
#   { player_name: "Ajinkya Rahane", sold_price: "10.5 CR" },
#   { player_name: "Arshdeep Singh", sold_price: "10 CR" },
#   { player_name: "Kwena Maphaka", sold_price: "20 L" },
#   { player_name: "Kuldeep Yadav", sold_price: "8.75 CR" },
#   { player_name: "Sandeep Sharma", sold_price: "5.75 CR" }
# ]