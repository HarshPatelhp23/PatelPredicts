ActiveAdmin.register Spl::User do
	permit_params :name, :email, :points, :is_admin

	index do
    selectable_column
    id_column
    column :name
    column :email
    column :points
    column :is_admin
    actions
  end
end