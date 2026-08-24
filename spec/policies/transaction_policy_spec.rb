require "rails_helper"

RSpec.describe TransactionPolicy, type: :policy do
  let(:user) do
    User.create!(
      name: "Transaction User",
      email: "transaction-user@example.com",
      password: "password123"
    )
  end

  let(:other_user) do
    User.create!(
      name: "Other Transaction User",
      email: "other-transaction-user@example.com",
      password: "password123"
    )
  end

  let(:category) do
    Category.create!(
      user: user,
      name: "Alimentação",
      is_income: false,
      icon: "🍔",
      color: "#ff6600"
    )
  end

   let(:account) do
    Account.create!(
      user: user,
      name: "Conta Principal",
      bank: "Banco do Brasil",
      initial_balance: 0
    )
  end

  let(:other_account) do
    Account.create!(
      user: other_user,
      name: "Outra Conta",
      bank: "Banco do Brasil",
      initial_balance: 0
    )
  end

  let(:transaction) do
    Transaction.create!(
      account: account,
      category: category,
      amount: 100,
      description: "Mercado",
      date: Date.current
    )
  end

  let(:other_transaction) do
    Transaction.create!(
      account: other_account,
      category: category,
      amount: 200,
      description: "Outra compra",
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
        Transaction.all
      ).resolve

      expect(resolved_scope).to contain_exactly(transaction)
    end
  end
end
