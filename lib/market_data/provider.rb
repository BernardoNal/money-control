module MarketData
  class Provider
    # Base contract for market data integrations.
    # Application services should depend on this interface instead of a concrete API client.
    def lookup_asset(symbol:)
      raise NotImplementedError, "#{self.class.name} must implement #lookup_asset"
    end

    def fetch_asset_metadata(symbol:)
      raise NotImplementedError, "#{self.class.name} must implement #fetch_asset_metadata"
    end

    def fetch_price(symbol:)
      raise NotImplementedError, "#{self.class.name} must implement #fetch_price"
    end
  end
end
