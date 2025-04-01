class PlayersTeam < ApplicationRecord
  belongs_to :player
  belongs_to :team
end
