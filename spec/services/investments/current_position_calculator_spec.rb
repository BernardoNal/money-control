require "rails_helper"

RSpec.describe Investments::CurrentPositionCalculator do
  let(:user) do
    User.create!(
      name: "Position Investor",
      email: "position-investor@example.com",
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

  it "returns zero quantity when there are no buy or sell transactions" do
    expect(result.quantity).to eq(BigDecimal("0"))
  end

  it "can be called through the class-level service interface" do
    create_transaction(:buy, quantity: 3, price: 10)

    result = described_class.call(portfolio: portfolio, asset: asset)

    expect(result.quantity).to eq(BigDecimal("3"))
  end

  it "accumulates quantity across multiple buy transactions" do
    create_transaction(:buy, quantity: 10, price: 20, date: Date.new(2026, 1, 1))
    create_transaction(:buy, quantity: 5, price: 30, date: Date.new(2026, 1, 2))

    expect(result.quantity).to eq(BigDecimal("15"))
  end

  it "reduces quantity after a partial sell" do
    create_transaction(:buy, quantity: 10, price: 20, date: Date.new(2026, 1, 1))
    create_transaction(:buy, quantity: 10, price: 40, date: Date.new(2026, 1, 2))
    create_transaction(:sell, quantity: 5, price: 50, date: Date.new(2026, 1, 3))

    expect(result.quantity).to eq(BigDecimal("15"))
  end

  it "resets quantity to zero after selling the full position" do
    create_transaction(:buy, quantity: 3, price: 100, date: Date.new(2026, 1, 1))
    create_transaction(:sell, quantity: 3, price: 120, date: Date.new(2026, 1, 2))

    expect(result.quantity).to eq(BigDecimal("0"))
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
