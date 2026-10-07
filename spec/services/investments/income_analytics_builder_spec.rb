require "rails_helper"

RSpec.describe Investments::IncomeAnalyticsBuilder do
  let(:user) do
    User.create!(
      name: "Analytics User",
      email: "analytics-user@example.com",
      password: "password123"
    )
  end

  let(:portfolio) do
    Investments::Portfolio.create!(
      name: "Analytics Portfolio",
      user: user
    )
  end

  let(:asset) do
    Investments::Asset.create!(
      name: "Asset One",
      symbol: "AST1",
      category: :stock,
      currency: "BRL"
    )
  end

  subject(:analytics) do
    described_class.call(incomes: Investments::Income.where(portfolio: portfolio))
  end

  it "summarizes received net income by type" do
    create_income(:dividends, gross_amount: 120, tax_amount: 20)
    create_income(:dividends, gross_amount: 80, tax_amount: 0)
    create_income(:jcp, gross_amount: 50, tax_amount: 5)

    expect(analytics.total_net_amount).to eq(BigDecimal("225"))
    expect(analytics.income_totals_by_type).to eq(
      "dividends" => BigDecimal("180"),
      "jcp" => BigDecimal("45")
    )
    expect(analytics.income_count).to eq(3)
  end

  it "returns zero totals for an empty relation" do
    expect(analytics.total_net_amount).to eq(BigDecimal("0"))
    expect(analytics.income_totals_by_type).to eq({})
    expect(analytics.income_count).to eq(0)
  end

  private

  def create_income(income_type, gross_amount:, tax_amount:)
    Investments::Income.create!(
      portfolio: portfolio,
      asset: asset,
      income_type: income_type,
      gross_amount: gross_amount,
      tax_amount: tax_amount,
      payment_date: Date.current
    )
  end
end
