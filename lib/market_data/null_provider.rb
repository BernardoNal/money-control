module MarketData
  class NullProvider < Provider
    # Explicit fallback used while no external provider is configured.
    # Failing fast here keeps the service boundary available without silently masking setup gaps.
    MESSAGE = "No market data provider configured".freeze

    def lookup_asset(symbol:)
      raise ConfigurationError, MESSAGE
    end

    def fetch_asset_metadata(symbol:)
      raise ConfigurationError, MESSAGE
    end

    def fetch_price(symbol:)
      raise ConfigurationError, MESSAGE
    end

    # Keeps the unconfigured-provider failure explicit for batch lookups.
    def fetch_prices(symbols:)
      raise ConfigurationError, MESSAGE
    end
  end
end
