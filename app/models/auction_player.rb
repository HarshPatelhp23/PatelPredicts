# frozen_string_literal: true

class AuctionPlayer < ApplicationRecord
  has_and_belongs_to_many :fantasy_teams, class_name: 'Spl::FantasyTeam',
                                          join_table: :fantasy_teams_auction_players,
                                          foreign_key: :auction_player_id,
                                          association_foreign_key: :spl_fantasy_team_id
  has_one :auction_room
  has_many :fantasy_teams_as_captain, class_name: 'Spl::FantasyTeam', foreign_key: 'captain_id', dependent: :destroy
  has_many :fantasy_teams_as_vice_captain, class_name: 'Spl::FantasyTeam', foreign_key: 'vice_captain_id', dependent: :destroy
  has_many :spl_users, through: :fantasy_teams
  delegate :user, to: :auction_room, allow_nil: true
  scope :unsold, -> { where(sold: false) }
  scope :sold, -> { where(sold: true) }
  after_create :generate_note
  after_update :update_associated_users_points, if: :saved_change_to_points?

  enum category: {
    legend:        0,
    power_batter:  1,
    strike_bowler: 2,
    all_rounder:   3,
    rising_star:   4
  }
 
  CATEGORY_META = {
    legend:        { label: "Legends of the League", sub: "Dominated batting, bowling & all seasons",  icon: "★" },
    power_batter:  { label: "Power Batters",          sub: "Runs machine — heavy bat over bowl",         icon: "🏏" },
    strike_bowler: { label: "Strike Bowlers",         sub: "Wicket takers — heavy bowl over bat",        icon: "🎯" },
    all_rounder:   { label: "True All-Rounders",      sub: "Equally dominant with bat and ball",         icon: "⚡" },
    rising_star:   { label: "Rising Stars",           sub: "New comers with potential to surprise",      icon: "✦" }
  }.freeze
 
  def as_json_for_team
    {
      id:       id,
      name:     name,
      category: category,
      # ipl_team: ipl_team.to_s,
      # batting/bowling come from original schema (integers)
      runs:     batting.to_i,
      wickets:  self[:wickets].to_s,   # string column per migration
      fifties:  self[:fifties].to_s,   # string column per migration
      hundreds: self[:hundreds].to_s,  # string column per migration
      trophies: trophies_won.to_i,         # if you add this column later; 0 for now
      points:   self[:points].to_f
    }
  end

  def name_with_role
    if batting > 75 && bowling > 75
       "#{name}" '(All-Rounder)'
    else
      "#{name} (#{batting > bowling ? 'Batsman' : 'Bowler'})"
    end
  end

  def sold_price
    "#{auction_room.amount}" + " " + auction_room.amount_unit
  end

  def total_skill
    batting + bowling
  end

  def generate_note
    notes = if batting == 50 && bowling == 50
              [
                "This player hasn't showcased their skills yet, making them a potential wildcard for the team.",
                'A fresh face with untapped potential—this player could be your secret weapon.',
                'Though no stats are available, this player might surprise everyone on the field.',
                'An untested player with lots of room for growth—worth a risk for adventurous selectors.',
                'No batting or bowling stats yet, but every underdog has its day. Will this be theirs?'
              ]
            elsif batting == 50
              [
                'A bowling maestro who can turn the tide of any game with their precision and power.',
                'An absolute bowling powerhouse—perfect for controlling the game.',
                'Their batting might be untested, but their bowling makes them a game-changer.',
                'This player is ready to deliver unforgettable performances with their bowling.',
                'A true bowling star, prepared to deliver crucial wickets when needed.'
              ]
            elsif bowling == 50
              [
                'With a solid batting game, this player is a run-scoring machine for the team.',
                'A master batsman who dominates the scoreboard with every hit.',
                'This player is all about the big hits—expect fireworks!',
                "They're a consistent performer who can carry the team to victory.",
                'Though untested in bowling, their batting makes them a top pick.'
              ]
            else
              [
                'An all-rounder with a perfect balance of skills—ideal for any team.',
                'This player excels in all aspects—truly a star who can contribute everywhere.',
                'A versatile player offering unmatched flexibility across different areas.',
                'A complete package—ready to perform in any situation and contribute to both batting and bowling.',
                'With strengths in both batting and bowling, this player is the ultimate team player.'
              ]
            end

    # Select a note with slight randomness to ensure uniqueness
    notes.sample
  end

  private

  def update_associated_users_points
    # Find all fantasy teams that have this player in playing11, as captain, or vice captain
    fantasy_teams = Spl::FantasyTeam.where(
      "playing11 @> ARRAY[?] OR captain_id = ? OR vice_captain_id = ?",
      id, id, id
    )
    
    # Update total points for each user
    fantasy_teams.find_each do |team|
      team.spl_user.update_total_points!
    end
  end
end
