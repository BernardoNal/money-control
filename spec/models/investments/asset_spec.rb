require "rails_helper"

RSpec.describe Investments::Asset, type: :model do
  subject(:asset) do
    described_class.new(
      name: "Apple Inc.",
      symbol: "AAPL",
      category: :international,
      currency: "USD"
    )
  end

  it "is valid with required attributes" do
    expect(asset).to be_valid
  end

  it "is invalid without a name" do
    asset.name = nil

    expect(asset).not_to be_valid
    expect(asset.errors[:name]).to include("can't be blank")
  end

  it "is invalid without a symbol" do
    asset.symbol = nil

    expect(asset).not_to be_valid
    expect(asset.errors[:symbol]).to include("can't be blank")
  end

  it "is invalid without a category" do
    asset.category = nil

    expect(asset).not_to be_valid
    expect(asset.errors[:category]).to include("can't be blank")
  end

  it "is invalid without a currency" do
    asset.currency = nil

    expect(asset).not_to be_valid
    expect(asset.errors[:currency]).to include("can't be blank")
  end

  it "does not allow duplicate symbols" do
    described_class.create!(
      name: "Apple Inc.",
      symbol: "AAPL",
      category: :international,
      currency: "USD"
    )

    expect(asset).not_to be_valid
    expect(asset.errors[:symbol]).to include("has already been taken")
  end

  it "defines the expected categories" do
    expect(described_class.categories.keys).to contain_exactly(
      "stock",
      "fii",
      "etf",
      "crypto",
      "fixed_income",
      "international"
    )
  end

  it "defaults active to true" do
    asset.save!

    expect(asset.active).to be(true)
  end
end
