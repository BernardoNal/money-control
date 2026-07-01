require "rails_helper"

RSpec.describe MarketData::AssetLookupService do
  describe "#call" do
    it "delegates asset lookup to the injected provider with a normalized symbol" do
      asset_data = MarketData::AssetData.new(
        symbol: "AAPL",
        name: "Apple Inc.",
        currency: "USD",
        category: "international",
        subcategory: "technology",
        active: true
      )

      provider = instance_double(MarketData::Provider)
      allow(provider).to receive(:lookup_asset).with(symbol: "AAPL").and_return(asset_data)

      result = described_class.new(provider: provider).call(symbol: " aapl ")

      expect(result).to eq(asset_data)
      expect(provider).to have_received(:lookup_asset).with(symbol: "AAPL")
    end

    it "uses the null provider by default" do
      expect { described_class.new.call(symbol: "AAPL") }
        .to raise_error(MarketData::ConfigurationError, "No market data provider configured")
    end
  end
end
