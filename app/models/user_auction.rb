class UserAuction < ApplicationRecord
  belongs_to :user
  belongs_to :auction
end
