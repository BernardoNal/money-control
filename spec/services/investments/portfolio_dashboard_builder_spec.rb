require "rails_helper"

RSpec.describe Investments::PortfolioDashboardBuilder do
  let(:user) do
    User.create!(
      name: "Dashboard Investor",
      email: "dashboard-investor@example.com",
      password: "password123"
    )
  end

  let(:portfolio) do
    Investments::Portfolio.create!(
      user: user,
      name: "Main Portfolio"
    )
  end

  let(:stock_asset) do
    Investments::Asset.create!(
      name: "Apple Inc.",
      symbol: "AAPL",
      category: :international,
      subcategory: :technology,
      currency: "USD"
    )
  end

  let(:fii_asset) do
    Investments::Asset.create!(
      name: "XP Malls",
      symbol: "XPML11",
      category: :fii,
      subcategory: :brick,
      currency: "BRL"
    )
  end

  let(:price_lookup_service) { instance_double(MarketData::PriceLookupService) }

  subject(:dashboard) { described_class.call(portfolio: portfolio, price_lookup_service: price_lookup_service) }

  before do
    allow(price_lookup_service).to receive(:call) do |symbol:|
      case symbol
      when "AAPL"
        MarketData::PriceData.new(
          symbol: "AAPL",
          price: BigDecimal("35"),
          currency: "USD",
          as_of: Time.zone.parse("2026-07-13 10:00:00")
        )
      when "XPML11"
        MarketData::PriceData.new(
          symbol: "XPML11",
          price: BigDecimal("11"),
          currency: "BRL",
          as_of: Time.zone.parse("2026-07-13 10:00:00")
        )
      else
        raise MarketData::NotFoundError, "missing"
      end
    end
  end

  it "returns zeroed summary when the portfolio has no positions or incomes" do
    expect(dashboard.total_invested_amount).to eq(BigDecimal("0"))
    expect(dashboard.current_portfolio_value).to eq(BigDecimal("0"))
    expect(dashboard.unrealized_profit_loss).to eq(BigDecimal("0"))
    expect(dashboard.passive_income_summary).to eq(BigDecimal("0"))
    expect(dashboard.historical_evolution_points).to be_empty
    expect(dashboard.asset_entries).to be_empty
    expect(dashboard.category_allocations).to be_empty
    expect(dashboard.subcategory_allocations).to be_empty
  end

  it "builds asset entries and current market totals from current positions" do
    create_transaction(stock_asset, :buy, quantity: 10, price: 20, fees: 5, date: Date.new(2026, 1, 1))
    create_transaction(stock_asset, :buy, quantity: 5, price: 30, fees: 10, date: Date.new(2026, 1, 2))
    create_transaction(stock_asset, :sell, quantity: 5, price: 40, fees: 0, date: Date.new(2026, 1, 3))
    create_transaction(fii_asset, :buy, quantity: 20, price: 10, fees: 0, date: Date.new(2026, 1, 4))

    expected_apple_cost = BigDecimal("365") - ((BigDecimal("365") / BigDecimal("15")) * BigDecimal("5"))
    expected_total = expected_apple_cost + BigDecimal("200")
    expected_current_value = (BigDecimal("35") * BigDecimal("10")) + (BigDecimal("11") * BigDecimal("20"))

    expect(dashboard.total_invested_amount).to eq(expected_total)
    expect(dashboard.current_portfolio_value).to eq(expected_current_value)
    expect(dashboard.unrealized_profit_loss).to eq(expected_current_value - expected_total)
    expect(dashboard.asset_entries.map { |entry| entry.asset.symbol }).to eq(%w[AAPL XPML11])

    apple_entry = dashboard.asset_entries.find { |entry| entry.asset == stock_asset }
    fii_entry = dashboard.asset_entries.find { |entry| entry.asset == fii_asset }

    expect(apple_entry.quantity).to eq(BigDecimal("10"))
    expect(apple_entry.average_price).to eq(expected_apple_cost / BigDecimal("10"))
    expect(apple_entry.invested_amount).to eq(expected_apple_cost)
    expect(apple_entry.market_price).to eq(BigDecimal("35"))
    expect(apple_entry.current_value).to eq(BigDecimal("350"))
    expect(apple_entry.price_source).to eq(:market)

    expect(fii_entry.quantity).to eq(BigDecimal("20"))
    expect(fii_entry.average_price).to eq(BigDecimal("10"))
    expect(fii_entry.invested_amount).to eq(BigDecimal("200"))
    expect(fii_entry.market_price).to eq(BigDecimal("11"))
    expect(fii_entry.current_value).to eq(BigDecimal("220"))
    expect(fii_entry.price_source).to eq(:market)
  end

  it "builds category allocations from the current invested positions" do
    local_stock_asset = Investments::Asset.create!(
      name: "Banco do Brasil",
      symbol: "BBAS3",
      category: :stock,
      currency: "BRL"
    )

    create_transaction(stock_asset, :buy, quantity: 10, price: 20, fees: 0, date: Date.new(2026, 1, 1))
    create_transaction(fii_asset, :buy, quantity: 5, price: 10, fees: 0, date: Date.new(2026, 1, 2))
    create_transaction(local_stock_asset, :buy, quantity: 3, price: 50, fees: 0, date: Date.new(2026, 1, 3))

    expect(dashboard.category_allocations.map(&:category)).to eq(%w[international stock fii])

    international_allocation = dashboard.category_allocations.find { |entry| entry.category == "international" }
    stock_allocation = dashboard.category_allocations.find { |entry| entry.category == "stock" }
    fii_allocation = dashboard.category_allocations.find { |entry| entry.category == "fii" }

    expect(international_allocation.label).to eq("Internacional")
    expect(international_allocation.invested_amount).to eq(BigDecimal("200"))
    expect(international_allocation.allocation_percentage).to eq(BigDecimal("50"))

    expect(stock_allocation.label).to eq("Ações")
    expect(stock_allocation.invested_amount).to eq(BigDecimal("150"))
    expect(stock_allocation.allocation_percentage).to eq(BigDecimal("37.5"))

    expect(fii_allocation.label).to eq("Fundos Imobiliários")
    expect(fii_allocation.invested_amount).to eq(BigDecimal("50"))
    expect(fii_allocation.allocation_percentage).to eq(BigDecimal("12.5"))
  end

  it "builds subcategory allocations from the current invested positions" do
    local_stock_asset = Investments::Asset.create!(
      name: "Banco do Brasil",
      symbol: "BBAS3",
      category: :stock,
      subcategory: :banks,
      currency: "BRL"
    )

    no_subcategory_asset = Investments::Asset.create!(
      name: "Tesouro Selic",
      symbol: "SELIC2029",
      category: :fixed_income,
      currency: "BRL"
    )

    create_transaction(stock_asset, :buy, quantity: 10, price: 20, fees: 0, date: Date.new(2026, 1, 1))
    create_transaction(fii_asset, :buy, quantity: 5, price: 10, fees: 0, date: Date.new(2026, 1, 2))
    create_transaction(local_stock_asset, :buy, quantity: 3, price: 50, fees: 0, date: Date.new(2026, 1, 3))
    create_transaction(no_subcategory_asset, :buy, quantity: 2, price: 25, fees: 0, date: Date.new(2026, 1, 4))

    expected_total = BigDecimal("450")

    expect(dashboard.subcategory_allocations.map(&:label)).to eq(
      ["Tecnologia", "Bancos", "Sem subcategoria", "Tijolo"]
    )

    technology_allocation = dashboard.subcategory_allocations.find { |entry| entry.subcategory == "technology" }
    banks_allocation = dashboard.subcategory_allocations.find { |entry| entry.subcategory == "banks" }
    brick_allocation = dashboard.subcategory_allocations.find { |entry| entry.subcategory == "brick" }
    uncategorized_allocation = dashboard.subcategory_allocations.find { |entry| entry.subcategory.nil? }

    expect(technology_allocation.invested_amount).to eq(BigDecimal("200"))
    expect(technology_allocation.allocation_percentage).to eq((BigDecimal("200") / expected_total) * 100)

    expect(banks_allocation.invested_amount).to eq(BigDecimal("150"))
    expect(banks_allocation.allocation_percentage).to eq((BigDecimal("150") / expected_total) * 100)

    expect(brick_allocation.invested_amount).to eq(BigDecimal("50"))
    expect(brick_allocation.allocation_percentage).to eq((BigDecimal("50") / expected_total) * 100)

    expect(uncategorized_allocation.label).to eq("Sem subcategoria")
    expect(uncategorized_allocation.invested_amount).to eq(BigDecimal("50"))
    expect(uncategorized_allocation.allocation_percentage).to eq((BigDecimal("50") / expected_total) * 100)
  end

  it "builds historical evolution points from dated transactions" do
    create_transaction(stock_asset, :buy, quantity: 10, price: 20, fees: 0, date: Date.new(2026, 1, 1))
    create_transaction(fii_asset, :buy, quantity: 5, price: 10, fees: 0, date: Date.new(2026, 1, 2))
    create_transaction(stock_asset, :sell, quantity: 2, price: 25, fees: 0, date: Date.new(2026, 1, 3))

    expect(dashboard.historical_evolution_points.map(&:date)).to eq(
      [Date.new(2026, 1, 1), Date.new(2026, 1, 2), Date.new(2026, 1, 3)]
    )
    expect(dashboard.historical_evolution_points.map(&:invested_amount)).to eq(
      [BigDecimal("200"), BigDecimal("250"), BigDecimal("210")]
    )
  end

  it "falls back to invested amount when no market price is available" do
    allow(price_lookup_service).to receive(:call).with(symbol: "SELIC2029").and_raise(MarketData::NotFoundError, "missing")

    fixed_income_asset = Investments::Asset.create!(
      name: "Tesouro Selic",
      symbol: "SELIC2029",
      category: :fixed_income,
      currency: "BRL"
    )

    create_transaction(fixed_income_asset, :buy, quantity: 2, price: 50, fees: 0, date: Date.new(2026, 1, 4))

    entry = dashboard.asset_entries.find { |item| item.asset == fixed_income_asset }

    expect(entry.market_price).to be_nil
    expect(entry.current_value).to eq(BigDecimal("100"))
    expect(entry.price_source).to eq(:cost_basis)
    expect(dashboard.market_value_approximation).to be(true)
    expect(dashboard.unpriced_asset_symbols).to include("SELIC2029")
  end

  it "calculates passive income summary from net amounts" do
    create_income(stock_asset, net_amount: 85, gross_amount: 100, tax_amount: 15)
    create_income(fii_asset, net_amount: 42, gross_amount: 42, tax_amount: 0)

    expect(dashboard.passive_income_summary).to eq(BigDecimal("127"))
  end

  it "ignores transactions and incomes from other portfolios" do
    other_portfolio = Investments::Portfolio.create!(user: user, name: "Other Portfolio")

    create_transaction(stock_asset, :buy, quantity: 2, price: 10, portfolio: portfolio)
    create_transaction(stock_asset, :buy, quantity: 100, price: 1, portfolio: other_portfolio)
    create_income(stock_asset, net_amount: 5, gross_amount: 5, tax_amount: 0, portfolio: portfolio)
    create_income(stock_asset, net_amount: 99, gross_amount: 99, tax_amount: 0, portfolio: other_portfolio)

    expect(dashboard.total_invested_amount).to eq(BigDecimal("20"))
    expect(dashboard.passive_income_summary).to eq(BigDecimal("5"))
    expect(dashboard.asset_entries.first.quantity).to eq(BigDecimal("2"))
  end

  def create_transaction(asset, transaction_type, quantity:, price:, fees: 0, date: Date.new(2026, 1, 1), portfolio: self.portfolio)
    Investments::Transaction.create!(
      portfolio: portfolio,
      asset: asset,
      transaction_type: transaction_type,
      quantity: quantity,
      price: price,
      fees: fees,
      date: date
    )
  end

  def create_income(asset, net_amount:, gross_amount:, tax_amount:, payment_date: Date.current, portfolio: self.portfolio)
    Investments::Income.create!(
      portfolio: portfolio,
      asset: asset,
      income_type: :dividends,
      gross_amount: gross_amount,
      net_amount: net_amount,
      tax_amount: tax_amount,
      payment_date: payment_date
    )
  end
end
