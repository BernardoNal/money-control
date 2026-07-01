require "rails_helper"

RSpec.describe MarketData::NullProvider do
  subject(:provider) { described_class.new }

  it "raises a configuration error for asset lookup" do
    expect { provider.lookup_asset(symbol: "AAPL") }
      .to raise_error(MarketData::ConfigurationError, "No market data provider configured")
  end

  it "raises a configuration error for metadata retrieval" do
    expect { provider.fetch_asset_metadata(symbol: "AAPL") }
      .to raise_error(MarketData::ConfigurationError, "No market data provider configured")
  end

  it "raises a configuration error for price retrieval" do
    expect { provider.fetch_price(symbol: "AAPL") }
      .to raise_error(MarketData::ConfigurationError, "No market data provider configured")
  end
end
