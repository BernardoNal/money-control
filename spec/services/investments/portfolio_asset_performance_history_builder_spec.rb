require "rails_helper"
require "market_data/price_data"

RSpec.describe Investments::PortfolioAssetPerformanceHistoryBuilder do
  let(:user) do
    User.create!(name: "History User", email: "history@example.com", password: "password123")
  end
  let!(:portfolio) { Investments::Portfolio.create!(user: user, name: "Main") }
  let!(:other_portfolio) { Investments::Portfolio.create!(user: user, name: "Other") }
  let!(:asset) { Investments::Asset.create!(name: "Apple Inc.", symbol: "AAPL34", category: :international, currency: "BRL") }
  let!(:other_asset) { Investments::Asset.create!(name: "Petrobras", symbol: "PETR4", category: :stock, currency: "BRL") }
  let(:price_lookup_service) { instance_double(MarketData::PriceLookupService) }

  before do
    Investments::Transaction.create!(
      portfolio: portfolio, asset: asset, transaction_type: :buy,
      quantity: 10, price: 10, fees: 1, date: Date.new(2026, 1, 10)
    )
    Investments::Transaction.create!(
      portfolio: portfolio, asset: asset, transaction_type: :sell,
      quantity: 2, price: 12, fees: 0.5, date: Date.new(2026, 2, 10)
    )
    allow(price_lookup_service).to receive(:historical_prices).and_return(
      [
        MarketData::HistoricalPriceData.new(symbol: "AAPL34", price: BigDecimal("10"), as_of: Date.new(2026, 1, 10)),
        MarketData::HistoricalPriceData.new(symbol: "AAPL34", price: BigDecimal("11"), as_of: Date.new(2026, 2, 10))
      ]
    )
  end

  it "builds market value and invested cost for each historical price" do
    result = described_class.call(portfolio: portfolio, asset: asset, price_lookup_service: price_lookup_service)

    expect(result.source).to eq(:market)
    expect(result.points).to contain_exactly(
      have_attributes(
        date: Date.new(2026, 1, 10), quantity: BigDecimal("10"),
        invested_amount: BigDecimal("101"), market_value: BigDecimal("100")
      ),
      have_attributes(
        date: Date.new(2026, 2, 10), quantity: BigDecimal("8"),
        invested_amount: BigDecimal("80.8"), market_value: BigDecimal("88")
      )
    )
  end

  it "requests only the selected portfolio and asset history" do
    Investments::Transaction.create!(
      portfolio: other_portfolio, asset: asset, transaction_type: :buy,
      quantity: 100, price: 1, fees: 0, date: Date.new(2026, 1, 1)
    )
    Investments::Transaction.create!(
      portfolio: portfolio, asset: other_asset, transaction_type: :buy,
      quantity: 100, price: 1, fees: 0, date: Date.new(2026, 1, 1)
    )

    described_class.call(portfolio: portfolio, asset: asset, price_lookup_service: price_lookup_service)

    expect(price_lookup_service).to have_received(:historical_prices).with(
      symbol: "AAPL34",
      asset_category: "international",
      start_date: Date.new(2026, 1, 10),
      end_date: Date.current
    )
  end

  it "marks the history unavailable when the market data source has no points" do
    allow(price_lookup_service).to receive(:historical_prices).and_return([])

    result = described_class.call(portfolio: portfolio, asset: asset, price_lookup_service: price_lookup_service)

    expect(result).to have_attributes(points: [], source: :unavailable)
  end
end
