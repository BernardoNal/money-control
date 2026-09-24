module MarketData
  class PriceLookupService
    def initialize(provider: Providers::BrapiProvider.new)
      @provider = provider
    end

    # Normalizes the ticker before delegating so all providers receive a stable symbol shape.
    def call(symbol:)
      provider.fetch_price(symbol: normalize_symbol(symbol))
    end

    # Batches normalized symbols and indexes returned prices for dashboard consumers.
    def call_many(symbols:)
      normalized_symbols = symbols.map { |symbol| normalize_symbol(symbol) }.reject(&:blank?).uniq
      return {} if normalized_symbols.empty?

      provider.fetch_prices(symbols: normalized_symbols).each_with_object({}) do |price_data, prices|
        prices[normalize_symbol(price_data.symbol)] = price_data
      end
    end

    private

    attr_reader :provider

    def normalize_symbol(symbol)
      symbol.to_s.strip.upcase
    end
  end
end
