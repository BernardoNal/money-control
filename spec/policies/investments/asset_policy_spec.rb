require "rails_helper"

RSpec.describe Investments::AssetPolicy, type: :policy do
  let(:user) do
    User.create!(
      name: "Asset User",
      email: "asset-policy@example.com",
      password: "password123"
    )
  end

  let(:admin) do
    User.create!(
      name: "Asset Admin",
      email: "asset-admin@example.com",
      password: "password123",
      admin: true
    )
  end

  let(:asset) do
    Investments::Asset.new(
      name: "Apple Inc.",
      symbol: "AAPL",
      category: :international,
      currency: "USD"
    )
  end

  describe "create?" do
    it "denies regular users" do
      expect(described_class.new(user, asset).create?).to be(false)
    end

    it "permits administrators" do
      expect(described_class.new(admin, asset).create?).to be(true)
    end
  end

  describe "update?" do
    it "denies regular users" do
      expect(described_class.new(user, asset).update?).to be(false)
    end

    it "permits administrators" do
      expect(described_class.new(admin, asset).update?).to be(true)
    end
  end
end
