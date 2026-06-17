ActiveAdmin.register SplOtp do
	permit_params :email, :otp_code, :otp_sent_at, :verified

	index do
    selectable_column
    id_column
    column :email
    column :otp_code
    column :otp_sent_at
    column :verified
    actions
  end
end