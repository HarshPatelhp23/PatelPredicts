# frozen_string_literal: true

ActiveAdmin.register AuctionPlayer do
  permit_params :name, :batting, :bowling, :sold, :points, :base_price, :note, :order, :category


  index do
    selectable_column
    id_column
    column :name
    column :batting
    column :bowling
    column :sold
    column :points
    column :category
    actions
  end


  form do |f|
    f.inputs "Player Details" do
      f.input :name
      f.input :batting
      f.input :bowling
      f.input :points
      f.input :category, as: :select, collection: AuctionPlayer.categories.map { |key, value| [key.humanize, key] }
      f.input :base_price
      f.input :order
      f.input :note
      
      # Custom checkbox with explicit values
      f.input :sold, as: :select, 
              collection: [["No", false], ["Yes", true]], 
              include_blank: false,
              label: "Sold Status"
    end
    f.actions
  end
end
