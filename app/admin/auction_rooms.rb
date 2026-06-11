# frozen_string_literal: true

ActiveAdmin.register AuctionRoom do
  permit_params :player_name, :amount, :user_id, :amount_unit, :auction_player_id

  index do
    selectable_column
    id_column
    # column :player_name
    column :amount
    column :amount_unit, as: :select, collection: AuctionRoom.amount_units.keys.map { |key|
                                                    [key.titleize, key]
                                                  }, label: 'Unit', prompt: 'Select Unit'
    column :final_amount, &:current_integer_amount
    column 'Captain', :user_id do |record|
      record.user.username
    end
    actions
  end

  form do |f|
    f.inputs do
      f.input :auction_player_id, as: :select, collection: AuctionPlayer.unsold.map { |ap|
                                                             [ap.name, ap.id]
                                                           }, label: 'Player', prompt: 'Select Player'
      f.input :amount
      f.input :amount_unit, as: :select, collection: AuctionRoom.amount_units.keys.map { |key|
                                                       [key.titleize, key]
                                                     }, label: 'Unit', prompt: 'Select Unit'
      f.input :user_id, as: :select, collection: User.captains.map { |user| [user.username, user.id] }
    end
    f.actions
  end

  action_item :send_auction_email, only: :index do
    link_to 'Send Auction Summary Email', send_email_admin_auction_rooms_path, method: :post
  end

  # Define a custom route to handle the email
  collection_action :send_email, method: :post do
    AuctionMailer.auction_summary_email.deliver_now
    redirect_to admin_auction_rooms_path, notice: "Auction summary email sent successfully."
  end
end
