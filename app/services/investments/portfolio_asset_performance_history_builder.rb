module Investments
  class PortfolioAssetPerformanceHistoryBuilder
    Point = Struct.new(
      :date,
      :market_price,
      :quantity,
      :invested_amount,
      :market_value,
      keyword_init: true
    )

    Result = Struct.new(:points, :from_date, :to_date, :source, keyword_init: true)

    def self.call(portfolio:, asset:, price_lookup_service: MarketData::PriceLookupService.new)
      new(
        portfolio: portfolio,
        asset: asset,
        price_lookup_service: price_lookup_service
      ).call
    end

    def initialize(portfolio:, asset:, price_lookup_service:)
      @portfolio = portfolio
      @asset = asset
      @price_lookup_service = price_lookup_service
    end

    def call
      return empty_result if transactions.empty?

      prices = price_lookup_service.historical_prices(
        symbol: asset.symbol,
        asset_category: asset.category,
        start_date: from_date,
        end_date: to_date
      )
      return empty_result(source: :unavailable) if prices.blank?

      Result.new(
        points: build_points(prices),
        from_date: from_date,
        to_date: to_date,
        source: :market
      )
    rescue MarketData::ConfigurationError, MarketData::NotFoundError, MarketData::ProviderError
      empty_result(source: :unavailable)
    end

    private

    attr_reader :portfolio, :asset, :price_lookup_service

    def build_points(prices)
      quantity = BigDecimal("0")
      invested_amount = BigDecimal("0")
      transaction_index = 0

      # Applying events once, in order, keeps each point tied to the position that existed on that date.
      prices.sort_by(&:as_of).filter_map do |price_data|
        while transaction_index < transactions.length && transactions[transaction_index].date <= price_data.as_of
          quantity, invested_amount = apply_transaction(
            transactions[transaction_index],
            quantity,
            invested_amount
          )
          transaction_index += 1
        end

        Point.new(
          date: price_data.as_of,
          market_price: price_data.price,
          quantity: quantity,
          invested_amount: invested_amount,
          market_value: price_data.price * quantity
        )
      end
    end

    def apply_transaction(transaction, quantity, invested_amount)
      case transaction.transaction_type
      when "buy"
        [
          quantity + transaction.quantity,
          invested_amount + transaction_total(transaction)
        ]
      when "sell"
        raise ArgumentError, "sell quantity exceeds current position" if transaction.quantity > quantity

        average_price = invested_amount / quantity
        remaining_quantity = quantity - transaction.quantity
        remaining_cost = invested_amount - (average_price * transaction.quantity)
        [remaining_quantity, remaining_quantity.zero? ? BigDecimal("0") : remaining_cost]
      else
        [quantity, invested_amount]
      end
    end

    def transactions
      @transactions ||= Investments::Transaction
        .where(portfolio: portfolio, asset: asset)
        .where(transaction_type: [:buy, :sell])
        .order(:date, :id)
    end

    def transaction_total(transaction)
      (transaction.quantity * transaction.price) + transaction.fees
    end

    def from_date
      @from_date ||= transactions.first ? [transactions.first.date, Date.current.prev_year].max : Date.current.prev_year
    end

    def to_date
      Date.current
    end

    def empty_result(source: :unavailable)
      Result.new(points: [], from_date: from_date, to_date: to_date, source: source)
    end
  end
end
