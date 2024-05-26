# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
ActiveAdmin.register Auction do
  remove_filter :users
  permit_params :name, :starts_at, :status, :teams_count, :admin_user_id

  index do
    selectable_column
    id_column
    column :name
    column :starts_at
    column :status
    column :teams_count
    column :admin_user_id
    actions
  end

  form do |f|
    f.inputs 'Player Details' do
      f.input :name
      f.input :starts_at
      f.input :status
      f.input :teams_count
      f.input :admin_user_id, as: :select, collection: AdminUser.all.map { |au| [au.email.split('@')[0], au.id] }
    end
    f.actions
  end

  action_item :start_auction, only: :show do
    link_to 'Start Auction', auction_path, id: 'start-auction-button', data: { auction_id: resource.id }
  end

  controller do
    def start_auction
      auction = Auction.find(params[:auction_id])
      auction.update(status: 'active')
      # Notify users that the auction has started
      AuctionRoomChannel.broadcast_to(auction, start: true)
      # You can also add additional logic here, such as setting up the initial state of the auction
      redirect_to admin_auction_path(auction), notice: 'Auction has started.'
    end

    # Make the start_auction action accessible via AJAX
    respond_to :js, only: [:start_auction]
  end
end
# rubocop:enable Metrics/BlockLength
