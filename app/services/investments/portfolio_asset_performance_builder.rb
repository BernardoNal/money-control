module Investments
  class PortfolioAssetPerformanceBuilder
    Result = Struct.new(
      :portfolio,
      :asset,
      :total_invested_amount,
      :current_market_value,
      :realized_profit_loss,
      :unrealized_profit_loss,
      :income_total,
      :total_return,
      keyword_init: true
    )

    ZERO = BigDecimal("0")

    def self.call(portfolio:, asset:, current_market_value:)
      new(
        portfolio: portfolio,
        asset: asset,
        current_market_value: current_market_value
      ).call
    end

    def initialize(portfolio:, asset:, current_market_value:)
      @portfolio = portfolio
      @asset = asset
      @current_market_value = current_market_value.to_d
    end

    def call
      position = Investments::AveragePriceCalculator.call(portfolio: portfolio, asset: asset)
      realized_profit_loss = calculate_realized_profit_loss
      unrealized_profit_loss = current_market_value - position.total_cost
      income_total = portfolio.incomes.where(asset: asset).sum(:net_amount).to_d

      Result.new(
        portfolio: portfolio,
        asset: asset,
        total_invested_amount: position.total_cost,
        current_market_value: current_market_value,
        realized_profit_loss: realized_profit_loss,
        unrealized_profit_loss: unrealized_profit_loss,
        income_total: income_total,
        total_return: realized_profit_loss + unrealized_profit_loss + income_total
      )
    end

    private

    attr_reader :portfolio, :asset, :current_market_value

    def calculate_realized_profit_loss
      quantity = ZERO
      total_cost = ZERO
      realized_profit_loss = ZERO

      transactions.each do |transaction|
        case transaction.transaction_type
        when "buy"
          quantity += transaction.quantity
          total_cost += transaction_total(transaction)
        when "sell"
          raise ArgumentError, "sell quantity exceeds current position" if transaction.quantity > quantity

          average_price = total_cost / quantity
          sale_proceeds = (transaction.quantity * transaction.price) - transaction.fees
          realized_profit_loss += sale_proceeds - (average_price * transaction.quantity)
          quantity -= transaction.quantity
          total_cost -= average_price * transaction.quantity
          total_cost = ZERO if quantity.zero?
        end
      end

      realized_profit_loss
    end

    def transactions
      # Chronological order is required because realized profit depends on the cost at each sale.
      Investments::Transaction
        .where(portfolio: portfolio, asset: asset)
        .where(transaction_type: [:buy, :sell])
        .order(:date, :id)
    end

    def transaction_total(transaction)
      (transaction.quantity * transaction.price) + transaction.fees
    end
  end
end
