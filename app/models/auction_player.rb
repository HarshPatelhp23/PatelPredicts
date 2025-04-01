# frozen_string_literal: true

class AuctionPlayer < ApplicationRecord
  has_one :auction_room
  delegate :user, to: :auction_room, allow_nil: true
  scope :unsold, -> { where(sold: false) }
  scope :sold, -> { where(sold: true) }
  after_create :generate_note

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
end
