require "rails_helper"

RSpec.describe Investments::TransactionPolicy, type: :policy do
  let(:user) do
    User.create!(
      name: "Transaction User",
      email: "transaction-user@example.com",
      password: "password123"
    )
  end

  let(:other_user) do
    User.create!(
      name: "Other User",
      email: "other-transaction-user@example.com",
      password: "password123"
    )
  end

  let(:portfolio) do
    Investments::Portfolio.create!(
      user: user,
      name: "Principal"
    )
  end

  let(:other_portfolio) do
    Investments::Portfolio.create!(
      user: other_user,
      name: "Other Portfolio"
    )
  end

  let(:asset) do
    Investments::Asset.create!(
      name: "Apple Inc.",
      symbol: "AAPL",
      category: :international,
      subcategory: :technology,
      currency: "USD"
    )
  end

  let(:transaction) do
    Investments::Transaction.create!(
      portfolio: portfolio,
      asset: asset,
      transaction_type: :buy,
      quantity: 10,
      price: 100,
      date: Date.current
    )
  end

  let(:other_transaction) do
    Investments::Transaction.create!(
      portfolio: other_portfolio,
      asset: asset,
      transaction_type: :buy,
      quantity: 5,
      price: 100,
      date: Date.current
    )
  end

  describe "show?" do
    it "permits access to a transaction owned by the user" do
      policy = described_class.new(user, transaction)

      expect(policy.show?).to be(true)
    end

    it "denies access to a transaction owned by another user" do
      policy = described_class.new(user, other_transaction)

      expect(policy.show?).to be(false)
    end
  end

  describe "update?" do
    it "permits access to a transaction owned by the user" do
      policy = described_class.new(user, transaction)

      expect(policy.update?).to be(true)
    end

    it "denies access to a transaction owned by another user" do
      policy = described_class.new(user, other_transaction)

      expect(policy.update?).to be(false)
    end
  end

  describe "destroy?" do
    it "permits access to a transaction owned by the user" do
      policy = described_class.new(user, transaction)

      expect(policy.destroy?).to be(true)
    end

    it "denies access to a transaction owned by another user" do
      policy = described_class.new(user, other_transaction)

      expect(policy.destroy?).to be(false)
    end
  end

  describe "Scope" do
    it "returns only transactions owned by the user" do
      transaction
      other_transaction

      resolved_scope = described_class::Scope.new(
        user,
        Investments::Transaction.all
      ).resolve

      expect(resolved_scope).to contain_exactly(transaction)
    end
  end
end
