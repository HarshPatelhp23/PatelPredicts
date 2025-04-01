# frozen_string_literal: true

class TeamSkillEvaluator
  class << self
    def calculate_strength(captain, skill)
      team_players_strength = captain.auction_players.sum(skill.to_sym)
      return 0 if team_players_strength.zero?

      (team_players_strength / captain.auction_players.size.to_f).round(2)
    end

    def calculate_winning_chances(captain)
      all_captains = User.captains.includes(:auction_players)
      total_strength = calculate_total_strengths(all_captains)

      return '0%' if total_strength.zero?

      captain_team_strength = calculate_team_strength(captain)
      "#{((captain_team_strength / total_strength.to_f) * 100).round(2)}%"
    end

    def all_team_winning_chances
      all_captains = User.captains.includes(:auction_players)
      total_strength = calculate_total_strengths(all_captains)

      return {} if total_strength.zero?

      all_captains.each_with_object({}) do |captain, chances|
        captain_team_strength = calculate_team_strength(captain)
        chances[captain.id] = "#{((captain_team_strength / total_strength.to_f) * 100).round(2)}%"
      end
    end

    def all_team_max_bid
      max_bid = {}
      all_captains = User.captains

      all_captains.each do |captain|
        total_buys = captain.auction_players.count - captain.captain_player
        if total_buys.zero?
          max_bid[captain.id] = CurrencyFormatter.format(192_000_000)
        else
          total_remaining_spots = (6 - total_buys) - 1 # -1 for current player
          max_bid[captain.id] = CurrencyFormatter.format(captain.remaining_purse - (total_remaining_spots * 2_000_000))
        end
      end
      max_bid
    end

    def categorize_buy(base_price, total_skill, sold_price)
      # Calculate skill percentage, 200 is max skill 100(batting) + 100(bowling)
      skill_percent = total_skill.to_f / 200

      # Determine multipliers based on skill
      if skill_percent <= 0.67
        m1 = 10
        m2 = 15
        m3 = 20
      elsif skill_percent < 0.76
        m1 = 20
        m2 = 25
        m3 = 30
      else
        m1 = 30
        m2 = 35
        m3 = 40
      end
      # Calculate ranges
      price_ranges(base_price, m1, m2, m3).find { |_, range| range.include?(sold_price) }&.first.to_s
    end

    private

    def calculate_total_strengths(captains)
      captains.sum { |captain| calculate_team_strength(captain) }
    end

    def calculate_team_strength(captain)
      captain.auction_players.sum(:batting) + captain.auction_players.sum(:bowling)
    end

    def price_ranges(base_price, m1, m2, m3)
      {
        steal_deal: base_price..(m1 * base_price).to_i,
        best_buy: ((m1 * base_price) + 1).to_i..(m2 * base_price).to_i,
        avg_buy: ((m2 * base_price) + 1).to_i..(m3 * base_price).to_i,
        worst_buy: ((m3 * base_price) + 1).to_i..Float::INFINITY
      }
    end
  end
end
