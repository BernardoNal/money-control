require "rails_helper"

RSpec.describe Investments::PortfolioAssetDetailBuilder do
  let(:user) do
    User.create!(name: "Asset Detail User", email: "asset-detail@example.com", password: "password123")
  end

  let!(:portfolio) { Investments::Portfolio.create!(user: user, name: "Main") }
  let!(:asset) do
    Investments::Asset.create!(
      name: "Apple Inc.",
      symbol: "AAPL34",
      category: :international,
      currency: "BRL"
    )
  end

  let!(:buy) do
    Investments::Transaction.create!(
      portfolio: portfolio,
      asset: asset,
      transaction_type: :buy,
      quantity: 10,
      price: 10,
      fees: 1,
      date: Date.new(2026, 1, 10)
    )
  end

  let!(:sell) do
    Investments::Transaction.create!(
      portfolio: portfolio,
      asset: asset,
      transaction_type: :sell,
      quantity: 2,
      price: 12,
      fees: 0,
      date: Date.new(2026, 2, 10)
    )
  end

  it "builds the position and unrealized result from the latest market price" do
    price_data = MarketData::PriceData.new(
      symbol: "AAPL34",
      price: BigDecimal("12.00"),
      currency: "BRL",
      as_of: Time.zone.parse("2026-10-20 12:00:00")
    )
    price_lookup = instance_double(MarketData::PriceLookupService, call: price_data)

    result = described_class.call(portfolio: portfolio, asset: asset, price_lookup_service: price_lookup)

    expect(result).to have_attributes(
      quantity: BigDecimal("8.0"),
      average_price: BigDecimal("10.10"),
      total_invested_amount: BigDecimal("80.80"),
      market_price: BigDecimal("12.00"),
      current_market_value: BigDecimal("96.00"),
      unrealized_profit_loss: BigDecimal("15.20"),
      price_source: :market
    )
    expect(result.unrealized_profit_loss_percentage).to be_within(BigDecimal("0.01")).of(BigDecimal("18.8118"))
  end

  it "falls back to cost basis when market data is unavailable" do
    price_lookup = instance_double(MarketData::PriceLookupService)
    allow(price_lookup).to receive(:call).and_raise(MarketData::NotFoundError, "not found")

    result = described_class.call(portfolio: portfolio, asset: asset, price_lookup_service: price_lookup)

    expect(result).to have_attributes(
      market_price: nil,
      current_market_value: BigDecimal("80.80"),
      unrealized_profit_loss: BigDecimal("0"),
      unrealized_profit_loss_percentage: BigDecimal("0"),
      price_source: :cost_basis
    )
  end
end
