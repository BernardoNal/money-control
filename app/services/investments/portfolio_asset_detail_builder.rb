module Investments
  class PortfolioAssetDetailBuilder
    Result = Struct.new(
      :portfolio,
      :asset,
      :quantity,
      :average_price,
      :total_invested_amount,
      :market_price,
      :current_market_value,
      :unrealized_profit_loss,
      :unrealized_profit_loss_percentage,
      :price_as_of,
      :price_source,
      :annual_comparison,
      keyword_init: true
    )

    AnnualComparison = Struct.new(
      :reference_date,
      :reference_quantity,
      :reference_price,
      :reference_value,
      :current_value,
      :change,
      :change_percentage,
      keyword_init: true
    )

    ZERO = BigDecimal("0")
    REFERENCE_DATE_ENV = "PORTFOLIO_ASSET_COMPARISON_DATE".freeze

    def self.call(portfolio:, asset:, price_lookup_service: MarketData::PriceLookupService.new)
      new(portfolio: portfolio, asset: asset, price_lookup_service: price_lookup_service).call
    end

    def initialize(portfolio:, asset:, price_lookup_service:)
      @portfolio = portfolio
      @asset = asset
      @price_lookup_service = price_lookup_service
    end

    def call
      position = Investments::AveragePriceCalculator.call(portfolio: portfolio, asset: asset)
      price_data = fetch_market_price
      current_market_value = price_data ? price_data.price * position.quantity : position.total_cost
      profit_loss = current_market_value - position.total_cost

      Result.new(
        portfolio: portfolio,
        asset: asset,
        quantity: position.quantity,
        average_price: position.average_price,
        total_invested_amount: position.total_cost,
        market_price: price_data&.price,
        current_market_value: current_market_value,
        unrealized_profit_loss: profit_loss,
        unrealized_profit_loss_percentage: percentage_for(profit_loss, position.total_cost),
        price_as_of: price_data&.as_of,
        price_source: price_data ? :market : :cost_basis,
        annual_comparison: build_annual_comparison(current_market_value)
      )
    end

    private

    attr_reader :portfolio, :asset, :price_lookup_service

    def fetch_market_price
      price_lookup_service.call(symbol: asset.symbol)
    rescue MarketData::ConfigurationError, MarketData::NotFoundError, MarketData::ProviderError
      nil
    end

    def build_annual_comparison(current_value)
      reference_date = annual_reference_date
      reference_position = Investments::AveragePriceCalculator.call(
        portfolio: portfolio,
        asset: asset,
        as_of: reference_date
      )
      return if reference_position.quantity.zero?

      historical_price = fetch_historical_price(reference_date)
      return if historical_price.blank?

      reference_value = historical_price.price * reference_position.quantity
      change = current_value - reference_value

      AnnualComparison.new(
        reference_date: historical_price.as_of,
        reference_quantity: reference_position.quantity,
        reference_price: historical_price.price,
        reference_value: reference_value,
        current_value: current_value,
        change: change,
        change_percentage: percentage_for(change, reference_value)
      )
    rescue ArgumentError
      nil
    end

    def fetch_historical_price(date)
      price_lookup_service.historical_price(
        symbol: asset.symbol,
        asset_category: asset.category,
        date: date
      )
    rescue MarketData::ConfigurationError, MarketData::NotFoundError, MarketData::ProviderError
      nil
    end

    # Allows local verification against a known statement date without changing production behavior.
    def annual_reference_date
      configured_date = ENV[REFERENCE_DATE_ENV].presence
      return Date.iso8601(configured_date) if configured_date

      Date.current.prev_year.end_of_year
    rescue Date::Error
      Date.current.prev_year.end_of_year
    end

    def percentage_for(amount, base)
      return ZERO if base.zero?

      (amount / base) * 100
    end
  end
end
