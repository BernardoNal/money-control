require "rails_helper"

RSpec.describe Investments::IncomeImports::AssetSuggestionResolver do
  it "returns a suggestion when an issuer prefix has one catalog asset" do
    asset = Investments::Asset.new(symbol: "B3SA3")

    result = described_class.call(assets: [asset])

    expect(result).to eq("B3SA" => asset)
  end

  it "does not choose between multiple share classes for the same issuer" do
    assets = [
      Investments::Asset.new(symbol: "ABEV3"),
      Investments::Asset.new(symbol: "ABEV34")
    ]

    result = described_class.call(assets: assets)

    expect(result).to be_empty
  end

  it "normalizes issuer keys without changing the catalog assets" do
    asset = Investments::Asset.new(symbol: "brb3sa3")

    result = described_class.call(assets: [asset])

    expect(result["BRB3SA"]).to equal(asset)
    expect(asset.symbol).to eq("brb3sa3")
  end
end
