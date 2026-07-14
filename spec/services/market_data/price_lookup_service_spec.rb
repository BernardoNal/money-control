require "rails_helper"

RSpec.describe MarketData::PriceLookupService do
  describe "#call" do
    it "delegates price lookup to the injected provider with a normalized symbol" do
      price_data = MarketData::PriceData.new(
        symbol: "PETR4",
        price: BigDecimal("32.15"),
        currency: "BRL",
        as_of: Time.zone.parse("2026-07-13 10:00:00")
      )
      provider = instance_double(MarketData::Provider, fetch_price: price_data)

      result = described_class.new(provider: provider).call(symbol: "  petr4 ")

      expect(result).to eq(price_data)
      expect(provider).to have_received(:fetch_price).with(symbol: "PETR4")
    end
  end
end
