# frozen_string_literal: true

class CurrencyFormatter
  class << self
    def format(amount)
      return if amount.blank?

      if amount >= 10_000_000 # 1 crore
        "#{(amount / 10_000_000.0).round(2)} crore"
      elsif amount >= 100_000 # 1 lakh
        "#{(amount / 100_000.0).round(2)} lakh"
      else
        "₹#{ActionController::Base.helpers.number_with_delimiter(amount, delimiter: ',')}"
      end
    end
  end
end
