require "rails_helper"

RSpec.describe MarketData::Provider do
  subject(:provider) { described_class.new }

  it "defines the asset lookup contract" do
    expect { provider.lookup_asset(symbol: "AAPL") }
      .to raise_error(NotImplementedError, /must implement #lookup_asset/)
  end

  it "defines the asset metadata contract" do
    expect { provider.fetch_asset_metadata(symbol: "AAPL") }
      .to raise_error(NotImplementedError, /must implement #fetch_asset_metadata/)
  end

  it "defines the price contract" do
    expect { provider.fetch_price(symbol: "AAPL") }
      .to raise_error(NotImplementedError, /must implement #fetch_price/)
  end
end
