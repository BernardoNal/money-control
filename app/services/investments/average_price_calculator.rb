module Investments
  # Calculates the current position cost basis for one asset inside one portfolio.
  #
  # Business rules:
  # - buy operations increase quantity and total cost, including fees in the cost basis
  # - sell operations do not change the average price; they reduce cost proportionally
  # - selling the full position resets total cost and average price to zero
  # - selling more than the current position is treated as invalid historical data
  class AveragePriceCalculator
    Result = Struct.new(:quantity, :total_cost, :average_price, keyword_init: true)

    ZERO = BigDecimal("0")

    def initialize(portfolio:, asset:)
      @portfolio = portfolio
      @asset = asset
    end

    def self.call(portfolio:, asset:)
      new(portfolio: portfolio, asset: asset).call
    end

    def call
      quantity = ZERO
      total_cost = ZERO

      transactions.each do |transaction|
        case transaction.transaction_type
        when "buy"
          quantity += transaction.quantity
          total_cost += transaction_total(transaction)
        when "sell"
          raise ArgumentError, "sell quantity exceeds current position" if transaction.quantity > quantity

          average_price = average_price_for(quantity, total_cost)
          quantity -= transaction.quantity
          total_cost -= average_price * transaction.quantity
          total_cost = ZERO if quantity.zero?
        end
      end

      Result.new(
        quantity: quantity,
        total_cost: total_cost,
        average_price: average_price_for(quantity, total_cost)
      )
    end

    private

    attr_reader :portfolio, :asset

    def transactions
      # Chronological order is part of the calculation because each sell depends
      # on the position built by previous buy operations.
      Investments::Transaction
        .where(portfolio: portfolio, asset: asset)
        .where(transaction_type: [:buy, :sell])
        .order(:date, :id)
    end

    def transaction_total(transaction)
      (transaction.quantity * transaction.price) + transaction.fees
    end

    def average_price_for(quantity, total_cost)
      return ZERO if quantity.zero?

      total_cost / quantity
    end
  end
end
