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
    expect(asset.errors[:name]).to include("não pode ficar em branco")
  end

  it "is invalid without a symbol" do
    asset.symbol = nil

    expect(asset).not_to be_valid
    expect(asset.errors[:symbol]).to include("não pode ficar em branco")
  end

  it "is invalid without a category" do
    asset.category = nil

    expect(asset).not_to be_valid
    expect(asset.errors[:category]).to include("não pode ficar em branco")
  end

  it "is invalid without a currency" do
    asset.currency = nil

    expect(asset).not_to be_valid
    expect(asset.errors[:currency]).to include("não pode ficar em branco")
  end

  it "does not allow duplicate symbols" do
    described_class.create!(
      name: "Apple Inc.",
      symbol: "AAPL",
      category: :international,
      currency: "USD"
    )

    expect(asset).not_to be_valid
    expect(asset.errors[:symbol]).to include("já está em uso")
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

  it "defines the expected subcategories" do
    expect(described_class.subcategories.keys).to contain_exactly(
      "paper",
      "brick",
      "banks",
      "energy",
      "technology",
      "retail",
      "mining",
      "agribusiness",
      "logistics",
      "shopping_malls",
      "offices",
      "receivables",
      "utilities",
      "healthcare"
    )
  end

  it "defaults active to true" do
    asset.save!

    expect(asset.active).to be(true)
  end

  it "allows a subcategory compatible with the selected category" do
    asset.category = :stock
    asset.subcategory = :energy

    expect(asset).to be_valid
  end

  it "rejects a subcategory incompatible with the selected category" do
    asset.category = :stock
    asset.subcategory = :paper

    expect(asset).not_to be_valid
    expect(asset.errors[:subcategory]).to include("não é compatível com a categoria selecionada")
  end
end
