module MarketData
  class AssetLookupService
    def initialize(provider: Providers::BrapiProvider.new)
      @provider = provider
    end

    # Normalizes the ticker before delegating so future providers can receive a stable input shape.
    def call(symbol:)
      provider.lookup_asset(symbol: normalize_symbol(symbol))
    end

    private

    attr_reader :provider

    def normalize_symbol(symbol)
      symbol.to_s.strip.upcase
    end
  end
end
