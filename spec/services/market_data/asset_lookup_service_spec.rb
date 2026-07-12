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
      provider = instance_double(MarketData::Providers::BrapiProvider)
      allow(MarketData::Providers::BrapiProvider).to receive(:new).and_return(provider)
      allow(provider).to receive(:lookup_asset).with(symbol: "AAPL").and_return(
        MarketData::AssetData.new(
          symbol: "AAPL",
          name: "Apple Inc.",
          currency: "USD",
          category: "international",
          subcategory: nil,
          active: true
        )
      )

      result = described_class.new.call(symbol: "AAPL")

      expect(result.symbol).to eq("AAPL")
      expect(provider).to have_received(:lookup_asset).with(symbol: "AAPL")
    end
  end
end
