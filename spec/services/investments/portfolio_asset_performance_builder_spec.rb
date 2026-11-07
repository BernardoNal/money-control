require "rails_helper"

RSpec.describe Investments::PortfolioAssetPerformanceBuilder do
  let(:user) do
    User.create!(name: "Performance User", email: "performance@example.com", password: "password123")
  end

  let!(:portfolio) { Investments::Portfolio.create!(user: user, name: "Main") }
  let!(:other_portfolio) { Investments::Portfolio.create!(user: user, name: "Other") }
  let!(:asset) do
    Investments::Asset.create!(name: "Apple Inc.", symbol: "AAPL34", category: :international, currency: "BRL")
  end
  let!(:other_asset) do
    Investments::Asset.create!(name: "Petrobras", symbol: "PETR4", category: :stock, currency: "BRL")
  end

  before do
    Investments::Transaction.create!(
      portfolio: portfolio,
      asset: asset,
      transaction_type: :buy,
      quantity: 10,
      price: 10,
      fees: 1,
      date: Date.new(2026, 1, 10)
    )
    Investments::Transaction.create!(
      portfolio: portfolio,
      asset: asset,
      transaction_type: :sell,
      quantity: 2,
      price: 12,
      fees: 0.5,
      date: Date.new(2026, 2, 10)
    )
    Investments::Income.create!(
      portfolio: portfolio,
      asset: asset,
      income_type: :dividends,
      gross_amount: 6,
      tax_amount: 1,
      payment_date: Date.new(2026, 3, 10)
    )
  end

  it "separates realized, unrealized, and income results without double-counting invested cost" do
    result = described_class.call(
      portfolio: portfolio,
      asset: asset,
      current_market_value: BigDecimal("100")
    )

    expect(result).to have_attributes(
      total_invested_amount: BigDecimal("80.80"),
      current_market_value: BigDecimal("100"),
      realized_profit_loss: BigDecimal("3.30"),
      unrealized_profit_loss: BigDecimal("19.20"),
      income_total: BigDecimal("5"),
      total_return: BigDecimal("27.50")
    )
  end

  it "ignores transactions and incomes from other portfolios and assets" do
    Investments::Transaction.create!(
      portfolio: other_portfolio,
      asset: asset,
      transaction_type: :buy,
      quantity: 100,
      price: 1,
      fees: 0,
      date: Date.new(2026, 1, 1)
    )
    Investments::Transaction.create!(
      portfolio: portfolio,
      asset: other_asset,
      transaction_type: :buy,
      quantity: 100,
      price: 1,
      fees: 0,
      date: Date.new(2026, 1, 1)
    )
    Investments::Income.create!(
      portfolio: other_portfolio,
      asset: asset,
      income_type: :jcp,
      gross_amount: 100,
      tax_amount: 0,
      payment_date: Date.new(2026, 1, 1)
    )

    result = described_class.call(
      portfolio: portfolio,
      asset: asset,
      current_market_value: BigDecimal("100")
    )

    expect(result.income_total).to eq(BigDecimal("5"))
    expect(result.total_return).to eq(BigDecimal("27.50"))
  end
end
