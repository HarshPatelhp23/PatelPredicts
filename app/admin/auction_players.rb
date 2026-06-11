# frozen_string_literal: true

ActiveAdmin.register AuctionPlayer do
  permit_params :name, :batting, :bowling, :points, :base_price, :note, :order, :sold, :category


  index do
    selectable_column
    id_column
    column :name
    column :batting
    column :bowling
    column :points
    column :category
    actions
  end


  form do |f|
    f.inputs do
      f.input :name
      f.input :batting
      f.input :bowling
      f.input :points
      f.input :category, as: :select, collection: AuctionPlayer.categories.map { |key, value| [key.humanize, key] }

      f.input :base_price
      f.input :order
      f.input :sold
      f.input :note
    end
    f.actions
  end
end
