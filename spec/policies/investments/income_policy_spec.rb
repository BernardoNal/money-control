require "rails_helper"

RSpec.describe Investments::IncomePolicy, type: :policy do
  let(:user) do
    User.create!(
    name: "Income User",
    email: "income-user@example.com",
    password: "password123"
  )
  end

  let(:other_user) do
    User.create!(
      name: "Other Income User",
      email: "other-income-user@example.com",
      password: "password123"
    )
  end

  let(:portfolio) do
    Investments::Portfolio.create!(
      name: "Principal",
      user: user
    )
  end

  let(:other_portfolio) do
    Investments::Portfolio.create!(
      name: "Other Portfolio",
      user: other_user
    )
  end

  let(:asset) do
    Investments::Asset.create!(
      name: "MXRF11",
      symbol: "MXRF11",
      category: :fii,
      currency: "BRL"
    )
  end

  let(:income) do
    Investments::Income.create!(
      portfolio: portfolio,
      asset: asset,
      income_type: :dividends,
      gross_amount: 10,
      net_amount: 10,
      tax_amount: 0,
      payment_date: Date.current
    )
  end

  let(:other_income) do
    Investments::Income.create!(
      portfolio: other_portfolio,
      asset: asset,
      income_type: :dividends,
      gross_amount: 10,
      net_amount: 10,
      tax_amount: 0,
      payment_date: Date.current
    )
  end

  describe "show?" do
    it "permits access to an income owned by the user" do
      policy = described_class.new(user, income)

      expect(policy.show?).to be(true)
    end

    it "denies access to an income owned by another user" do
      policy = described_class.new(user, other_income)

      expect(policy.show?).to be(false)
    end
  end

  describe "update?" do
    it "permits access to an income owned by the user" do
      policy = described_class.new(user, income)

      expect(policy.update?).to be(true)
    end

    it "denies access to an income owned by another user" do
      policy = described_class.new(user, other_income)

      expect(policy.update?).to be(false)
    end
  end

  describe "destroy?" do
    it "permits access to an income owned by the user" do
      policy = described_class.new(user, income)

      expect(policy.destroy?).to be(true)
    end

    it "denies access to an income owned by another user" do
      policy = described_class.new(user, other_income)

      expect(policy.destroy?).to be(false)
    end
  end

  describe "Scope" do
    it "returns only incomes owned by the user" do
      income
      other_income

      resolved_scope = described_class::Scope.new(
        user,
        Investments::Income.all
      ).resolve

      expect(resolved_scope).to contain_exactly(income)
    end
  end
end
