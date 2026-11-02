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
      keyword_init: true
    )

    ZERO = BigDecimal("0")

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
        price_source: price_data ? :market : :cost_basis
      )
    end

    private

    attr_reader :portfolio, :asset, :price_lookup_service

    def fetch_market_price
      price_lookup_service.call(symbol: asset.symbol)
    rescue MarketData::ConfigurationError, MarketData::NotFoundError, MarketData::ProviderError
      nil
    end

    def percentage_for(amount, base)
      return ZERO if base.zero?

      (amount / base) * 100
    end
  end
end
