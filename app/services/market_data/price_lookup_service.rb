module MarketData
  class PriceLookupService
    def initialize(provider: Providers::BrapiProvider.new)
      @provider = provider
    end

    # Normalizes the ticker before delegating so all providers receive a stable symbol shape.
    def call(symbol:)
      provider.fetch_price(symbol: normalize_symbol(symbol))
    end

    private

    attr_reader :provider

    def normalize_symbol(symbol)
      symbol.to_s.strip.upcase
    end
  end
end
