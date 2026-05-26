module Investments
  class CurrentPositionCalculator
    Result = Struct.new(:quantity, keyword_init: true)

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

      transactions.each do |transaction|
        case transaction.transaction_type
        when "buy"
          quantity += transaction.quantity
        when "sell"
          raise ArgumentError, "sell quantity exceeds current position" if transaction.quantity > quantity

          quantity -= transaction.quantity
        end
      end

      Result.new(quantity: quantity)
    end

    private

    attr_reader :portfolio, :asset

    def transactions
      Investments::Transaction
        .where(portfolio: portfolio, asset: asset)
        .where(transaction_type: [:buy, :sell])
        .order(:date, :id)
    end
  end
end
