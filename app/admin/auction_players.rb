# frozen_string_literal: true

ActiveAdmin.register AuctionPlayer do
  permit_params :name, :batting, :bowling, :base_price

  form do |f|
    f.inputs do
      f.input :name
      f.input :batting
      f.input :bowling
      f.input :base_price
    end
    f.actions
  end
end
