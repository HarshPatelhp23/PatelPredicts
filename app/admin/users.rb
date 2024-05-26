# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
ActiveAdmin.register User do
  permit_params :id, :username, :email, :password, :password_confirmation, :confirmed_at, :grand_total, :auction_id,
                :final_total_points, :penalty_points, :otp_verified, :slug, :update_profile_count
  index do
    selectable_column
    id_column
    column :username
    column :email
    column :grand_total
    column :auction, as: :select, collection: Auction.pluck(:name)
    column :final_total_points
    column :penalty_points
    column :update_profile_count
    actions defaults: true do |user|
      link_to 'Assign Team', assign_team_admin_user_path(user), method: :get
    end
  end

  form do |f|
    f.inputs 'User Details' do
      f.input :username
      f.input :grand_total
      f.input :auction, as: :select, collection: Auction.all.map { |auc| [auc.name, auc.id] }
      f.input :final_total_points
      f.input :penalty_points
      f.input :otp_verified
      f.input :update_profile_count
    end
    f.actions
  end

  member_action :assign_team, method: %i[get post] do
    @user = User.friendly.find(params[:id])
    if request.post?
      clean_string = params['user']['data'].gsub("\r\n", '').gsub!(/\s+/, ' ') if params['user']['data'].present?
      data = instance_eval(clean_string) if clean_string.present?
      if data.instance_of?(Hash)
        data.each do |d|
          Player.create(
            name: d[0],
            team_id: @user&.team&.id,
            role: d[1][1],
            team_name: d[1][2],
            foreigner: d[1][3],
            bench: true
          )
        end
        redirect_to admin_users_path, notice: 'Team have been assign successfully'
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
      params.require(:user).permit(:username, :email, :password, :password_confirmation, :confirmed_at, :auction_id,
                                   :grand_total, :final_total_points, :penalty_points, :otp_verified, :slug,
                                   :update_profile_count)
    end
  end

  filter :email
  filter :grand_total
end
# rubocop:enable Metrics/BlockLength
