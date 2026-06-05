require "rails_helper"

RSpec.describe Investments::AveragePriceCalculator do
  # These examples describe the cost-basis rules used to calculate an investor's
  # current position for one asset inside one portfolio.
  let(:user) do
    User.create!(
      name: "Investor",
      email: "average-price-investor@example.com",
      password: "password123"
    )
  end

  let(:portfolio) do
    Investments::Portfolio.create!(
      user: user,
      name: "Main Portfolio"
    )
  end

  let(:asset) do
    Investments::Asset.create!(
      name: "Apple Inc.",
      symbol: "AAPL",
      category: :international,
      currency: "USD"
    )
  end

  subject(:result) { described_class.new(portfolio: portfolio, asset: asset).call }

  it "returns zero values when there are no buy or sell transactions" do
    expect(result.quantity).to eq(BigDecimal("0"))
    expect(result.total_cost).to eq(BigDecimal("0"))
    expect(result.average_price).to eq(BigDecimal("0"))
  end

  it "can be called through the class-level service interface" do
    create_transaction(:buy, quantity: 1, price: 15)

    result = described_class.call(portfolio: portfolio, asset: asset)

    expect(result.average_price).to eq(BigDecimal("15"))
  end

  it "calculates weighted average price for buy transactions including fees" do
    create_transaction(:buy, quantity: 10, price: 20, fees: 5, date: Date.new(2026, 1, 1))
    create_transaction(:buy, quantity: 5, price: 30, fees: 10, date: Date.new(2026, 1, 2))

    expect(result.quantity).to eq(BigDecimal("15"))
    expect(result.total_cost).to eq(BigDecimal("365"))
    expect(result.average_price).to eq(BigDecimal("365") / BigDecimal("15"))
  end

  it "keeps the average price after a partial sell and reduces total cost proportionally" do
    create_transaction(:buy, quantity: 10, price: 20, date: Date.new(2026, 1, 1))
    create_transaction(:buy, quantity: 10, price: 40, date: Date.new(2026, 1, 2))
    create_transaction(:sell, quantity: 5, price: 50, date: Date.new(2026, 1, 3))

    expect(result.quantity).to eq(BigDecimal("15"))
    expect(result.total_cost).to eq(BigDecimal("450"))
    expect(result.average_price).to eq(BigDecimal("30"))
  end

  it "resets total cost and average price after selling the full position" do
    create_transaction(:buy, quantity: 3, price: 100, date: Date.new(2026, 1, 1))
    create_transaction(:sell, quantity: 3, price: 120, date: Date.new(2026, 1, 2))

    expect(result.quantity).to eq(BigDecimal("0"))
    expect(result.total_cost).to eq(BigDecimal("0"))
    expect(result.average_price).to eq(BigDecimal("0"))
  end

  it "ignores transactions from other portfolios and assets" do
    other_portfolio = Investments::Portfolio.create!(user: user, name: "Other Portfolio")
    other_asset = Investments::Asset.create!(
      name: "Microsoft",
      symbol: "MSFT",
      category: :international,
      currency: "USD"
    )

    create_transaction(:buy, quantity: 2, price: 10)
    create_transaction(:buy, quantity: 100, price: 1, portfolio: other_portfolio)
    create_transaction(:buy, quantity: 100, price: 1, asset: other_asset)

    expect(result.quantity).to eq(BigDecimal("2"))
    expect(result.total_cost).to eq(BigDecimal("20"))
    expect(result.average_price).to eq(BigDecimal("10"))
  end

  it "raises an error when a sell exceeds the current position" do
    create_transaction(:buy, quantity: 1, price: 10, date: Date.new(2026, 1, 1))
    create_transaction(:sell, quantity: 2, price: 10, date: Date.new(2026, 1, 2))

    expect { result }.to raise_error(ArgumentError, "sell quantity exceeds current position")
  end

  def create_transaction(
    transaction_type,
    quantity:,
    price:,
    fees: 0,
    date: Date.new(2026, 1, 1),
    portfolio: self.portfolio,
    asset: self.asset
  )
    Investments::Transaction.create!(
      portfolio: portfolio,
      asset: asset,
      transaction_type: transaction_type,
      quantity: quantity,
      price: price,
      fees: fees,
      date: date
    )
  end
end
