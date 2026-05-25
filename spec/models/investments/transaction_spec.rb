require "rails_helper"

RSpec.describe Investments::Transaction, type: :model do
  let(:user) do
    User.create!(
      name: "Investor",
      email: "transaction-investor@example.com",
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
      name: "Bitcoin",
      symbol: "BTC",
      category: :crypto,
      currency: "USD"
    )
  end

  subject(:transaction) do
    described_class.new(
      portfolio: portfolio,
      asset: asset,
      transaction_type: :buy,
      quantity: 0.5,
      price: 250000.0,
      fees: 25.0,
      date: Date.current,
      notes: "Initial position"
    )
  end

  it "is valid with required attributes" do
    expect(transaction).to be_valid
  end

  it "belongs to a portfolio" do
    transaction.portfolio = nil

    expect(transaction).not_to be_valid
    expect(transaction.errors[:portfolio]).to include("must exist")
  end

  it "belongs to an asset" do
    transaction.asset = nil

    expect(transaction).not_to be_valid
    expect(transaction.errors[:asset]).to include("must exist")
  end

  it "is invalid without a transaction type" do
    transaction.transaction_type = nil

    expect(transaction).not_to be_valid
    expect(transaction.errors[:transaction_type]).to include("can't be blank")
  end

  it "is invalid without a quantity" do
    transaction.quantity = nil

    expect(transaction).not_to be_valid
    expect(transaction.errors[:quantity]).to include("can't be blank")
  end

  it "is invalid when quantity is zero" do
    transaction.quantity = 0

    expect(transaction).not_to be_valid
    expect(transaction.errors[:quantity]).to include("must be greater than 0")
  end

  it "is invalid without a date" do
    transaction.date = nil

    expect(transaction).not_to be_valid
    expect(transaction.errors[:date]).to include("can't be blank")
  end

  it "requires price for buy transactions" do
    transaction.price = nil

    expect(transaction).not_to be_valid
    expect(transaction.errors[:price]).to include("can't be blank")
  end

  it "requires price for sell transactions" do
    transaction.transaction_type = :sell
    transaction.price = nil

    expect(transaction).not_to be_valid
    expect(transaction.errors[:price]).to include("can't be blank")
  end

  it "allows missing price for split transactions" do
    transaction.transaction_type = :split
    transaction.price = nil

    expect(transaction).to be_valid
  end

  it "is invalid when fees are negative" do
    transaction.fees = -1

    expect(transaction).not_to be_valid
    expect(transaction.errors[:fees]).to include("must be greater than or equal to 0")
  end

  it "defines the expected transaction types" do
    expect(described_class.transaction_types.keys).to contain_exactly(
      "buy",
      "sell",
      "transfer",
      "split",
      "reverse_split"
    )
  end
end
