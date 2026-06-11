ActiveAdmin.register Spl::User do
	permit_params :name, :email, :points

	index do
    selectable_column
    id_column
    column :name
    column :email
    column :points
    actions
  end
end