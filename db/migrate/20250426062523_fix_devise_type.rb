class FixDeviseType < ActiveRecord::Migration[7.0]
  def up
    PushSubscription.where("endpoint LIKE ?", "%fcm.googleapis.com%")
                   .update_all(device_type: 'mobile')
  end

  def down
    # No way to perfectly reverse this, but you could:
    PushSubscription.where("endpoint LIKE ?", "%fcm.googleapis.com%")
                   .update_all(device_type: 'desktop')
  end
end
