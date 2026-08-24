require "rails_helper"

RSpec.describe Investments::PortfolioPolicy, type: :policy do
  let(:user) do
    User.create!(
      name: "Portfolio User",
      email: "portfolio-user@example.com",
      password: "password123"
    )
  end

  let(:other_user) do
    User.create!(
      name: "Other User",
      email: "other-user@example.com",
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

  describe "show?" do
    it "permits access to a portfolio owned by the user" do
      policy = described_class.new(user, portfolio)

      expect(policy.show?).to be(true)
    end

    it "denies access to a portfolio owned by another user" do
      policy = described_class.new(user, other_portfolio)

      expect(policy.show?).to be(false)
    end
  end

  describe "update?" do
    it "permits access to a portfolio owned by the user" do
      policy = described_class.new(user, portfolio)

      expect(policy.update?).to be(true)
    end

    it "denies access to a portfolio owned by another user" do
      policy = described_class.new(user, other_portfolio)

      expect(policy.update?).to be(false)
    end
  end

  describe "destroy?" do
    it "permits access to a portfolio owned by the user" do
      policy = described_class.new(user, portfolio)

      expect(policy.destroy?).to be(true)
    end

    it "denies access to a portfolio owned by another user" do
      policy = described_class.new(user, other_portfolio)

      expect(policy.destroy?).to be(false)
    end
  end

  describe "Scope" do
    it "returns only portfolios owned by the user" do
      portfolio
      other_portfolio

      resolved_scope = described_class::Scope.new(
        user,
        Investments::Portfolio.all
      ).resolve

      expect(resolved_scope).to contain_exactly(portfolio)
    end
  end
end
