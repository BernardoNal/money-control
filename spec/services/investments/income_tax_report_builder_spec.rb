require "rails_helper"

RSpec.describe Investments::IncomeTaxReportBuilder do
  let(:user) do
    User.create!(
      name: "Tax Report User",
      email: "tax-report-user@example.com",
      password: "password123"
    )
  end

  let(:other_user) do
    User.create!(
      name: "Other Tax Report User",
      email: "other-tax-report-user@example.com",
      password: "password123"
    )
  end

  let(:portfolio) { create_portfolio("Primary Portfolio", user) }
  let(:other_portfolio) { create_portfolio("Other Portfolio", other_user) }
  let(:asset) { create_asset("Asset One", "AST1") }
  let(:second_asset) { create_asset("Asset Two", "AST2") }

  it "filters by year, groups by asset and income type, orders records, and calculates totals" do
    older_dividend = create_income(
      portfolio: portfolio,
      asset: asset,
      income_type: :dividends,
      gross_amount: 100,
      tax_amount: 10,
      payment_date: Date.new(2026, 1, 10),
      reference_date: Date.new(2025, 12, 20)
    )
    newer_dividend = create_income(
      portfolio: portfolio,
      asset: asset,
      income_type: :dividends,
      gross_amount: 80,
      tax_amount: 8,
      payment_date: Date.new(2026, 6, 10)
    )
    create_income(
      portfolio: portfolio,
      asset: asset,
      income_type: :jcp,
      gross_amount: 50,
      tax_amount: 5,
      payment_date: Date.new(2026, 3, 10)
    )
    create_income(
      portfolio: portfolio,
      asset: second_asset,
      income_type: :fii_income,
      gross_amount: 40,
      tax_amount: 0,
      payment_date: Date.new(2026, 2, 10)
    )
    create_income(
      portfolio: portfolio,
      asset: asset,
      income_type: :dividends,
      gross_amount: 999,
      tax_amount: 0,
      payment_date: Date.new(2025, 12, 31)
    )

    report = described_class.call(
      incomes: Investments::Income.where(portfolio: portfolio),
      year: 2026
    )

    expect(report.year).to eq(2026)
    expect(report.asset_groups.map { |group| group.asset.symbol }).to eq(%w[AST1 AST2])
    expect(report.asset_groups.first.income_type_groups.map(&:income_type)).to eq(%w[dividends jcp])
    expect(report.asset_groups.first.income_type_groups.first.incomes).to eq([older_dividend, newer_dividend])
    expect(report.asset_groups.first.income_type_groups.first.totals).to eq(
      gross_amount: BigDecimal("180"),
      tax_amount: BigDecimal("18"),
      net_amount: BigDecimal("162")
    )
    expect(report.totals).to eq(
      gross_amount: BigDecimal("270"),
      tax_amount: BigDecimal("23"),
      net_amount: BigDecimal("247")
    )
  end

  it "uses only the records from the supplied scoped relation" do
    create_income(
      portfolio: portfolio,
      asset: asset,
      income_type: :dividends,
      gross_amount: 25,
      tax_amount: 0,
      payment_date: Date.new(2026, 5, 10)
    )
    create_income(
      portfolio: other_portfolio,
      asset: asset,
      income_type: :dividends,
      gross_amount: 999,
      tax_amount: 0,
      payment_date: Date.new(2026, 5, 10)
    )

    report = described_class.call(
      incomes: Investments::Income.where(portfolio: portfolio),
      year: 2026
    )

    expect(report.totals[:net_amount]).to eq(BigDecimal("25"))
  end

  it "returns an empty report for a year without incomes" do
    report = described_class.call(
      incomes: Investments::Income.where(portfolio: portfolio),
      year: 2026
    )

    expect(report.asset_groups).to eq([])
    expect(report.totals).to eq(
      gross_amount: BigDecimal("0"),
      tax_amount: BigDecimal("0"),
      net_amount: BigDecimal("0")
    )
  end

  it "rejects an invalid year" do
    expect do
      described_class.call(incomes: Investments::Income.none, year: "not-a-year")
    end.to raise_error(ArgumentError, "year must be a valid calendar year")
  end

  private

  def create_portfolio(name, owner)
    Investments::Portfolio.create!(name: name, user: owner)
  end

  def create_asset(name, symbol)
    Investments::Asset.create!(name: name, symbol: symbol, category: :stock, currency: "BRL")
  end

  def create_income(portfolio:, asset:, income_type:, gross_amount:, tax_amount:, payment_date:, reference_date: nil)
    Investments::Income.create!(
      portfolio: portfolio,
      asset: asset,
      income_type: income_type,
      gross_amount: gross_amount,
      tax_amount: tax_amount,
      payment_date: payment_date,
      reference_date: reference_date
    )
  end
end
