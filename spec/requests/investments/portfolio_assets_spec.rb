require "rails_helper"

RSpec.describe "Investments::PortfolioAssets", type: :request do
  let(:user) do
    User.create!(name: "Portfolio Asset User", email: "portfolio-asset@example.com", password: "password123")
  end

  let(:other_user) do
    User.create!(name: "Other User", email: "other-portfolio-asset@example.com", password: "password123")
  end

  let!(:portfolio) { Investments::Portfolio.create!(user: user, name: "Main") }
  let!(:other_portfolio) { Investments::Portfolio.create!(user: other_user, name: "Other") }
  let!(:asset) do
    Investments::Asset.create!(name: "Apple Inc.", symbol: "AAPL34", category: :international, currency: "BRL")
  end

  before { sign_in user }

  it "does not expose an asset through another user's portfolio" do
    Investments::Transaction.create!(
      portfolio: other_portfolio,
      asset: asset,
      transaction_type: :buy,
      quantity: 1,
      price: 10,
      fees: 0,
      date: Date.current
    )

    get investments_portfolio_asset_detail_path(other_portfolio, asset)

    expect(response).to redirect_to(root_path)
  end

  it "redirects when the asset has no transaction in the selected portfolio" do
    get investments_portfolio_asset_detail_path(portfolio, asset)

    expect(response).to redirect_to(investments_portfolio_path(portfolio))
    expect(flash[:alert]).to eq("Ativo não encontrado neste portfólio.")
  end

  it "renders the asset detail for a transaction in the user's portfolio" do
    Investments::Transaction.create!(
      portfolio: portfolio,
      asset: asset,
      transaction_type: :buy,
      quantity: 2,
      price: 10,
      fees: 0,
      date: Date.current
    )

    allow(MarketData::PriceLookupService).to receive(:new).and_return(
      instance_double(
        MarketData::PriceLookupService,
        call: MarketData::PriceData.new(symbol: asset.symbol, price: 12, currency: asset.currency, as_of: Time.current),
        historical_price: nil
      )
    )

    get investments_portfolio_asset_detail_path(portfolio, asset)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("AAPL34", "Resultado não realizado", "R$ 24,00", "R$ 4,00")
  end

  it "renders only the selected asset transactions in chronological order" do
    other_asset = Investments::Asset.create!(name: "Petrobras", symbol: "PETR4", category: :stock, currency: "BRL")
    Investments::Transaction.create!(
      portfolio: portfolio,
      asset: asset,
      transaction_type: :buy,
      quantity: 2,
      price: 10,
      fees: 1,
      date: Date.new(2026, 1, 10),
      notes: "Aporte inicial"
    )
    Investments::Transaction.create!(
      portfolio: portfolio,
      asset: asset,
      transaction_type: :sell,
      quantity: 1,
      price: 12,
      fees: 0,
      date: Date.new(2026, 2, 10)
    )
    Investments::Transaction.create!(
      portfolio: portfolio,
      asset: other_asset,
      transaction_type: :buy,
      quantity: 999,
      price: 7,
      fees: 0,
      date: Date.new(2026, 1, 5)
    )
    Investments::Transaction.create!(
      portfolio: other_portfolio,
      asset: asset,
      transaction_type: :buy,
      quantity: 50,
      price: 1,
      fees: 0,
      date: Date.new(2026, 1, 1)
    )

    allow(MarketData::PriceLookupService).to receive(:new).and_return(
      instance_double(MarketData::PriceLookupService, call: nil, historical_price: nil)
    )

    get investments_portfolio_asset_detail_path(portfolio, asset)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Histórico de transações", "Aporte inicial", "Compra", "Venda", "R$ 20,00", "R$ 12,00")
    expect(response.body.index("10/01/2026")).to be < response.body.index("10/02/2026")
    expect(response.body).not_to include("PETR4", "R$ 6.993,00")
  end

  it "renders corporate actions without inventing price or total values" do
    Investments::Transaction.create!(
      portfolio: portfolio,
      asset: asset,
      transaction_type: :buy,
      quantity: 2,
      price: 10,
      fees: 0,
      date: Date.new(2026, 1, 1)
    )
    Investments::Transaction.create!(
      portfolio: portfolio,
      asset: asset,
      transaction_type: :transfer,
      quantity: 2,
      price: nil,
      fees: 0,
      date: Date.new(2026, 1, 2),
      notes: "Transferência entre custódias"
    )
    Investments::Transaction.create!(
      portfolio: portfolio,
      asset: asset,
      transaction_type: :split,
      quantity: 4,
      price: nil,
      fees: 0,
      date: Date.new(2026, 1, 3)
    )
    Investments::Transaction.create!(
      portfolio: portfolio,
      asset: asset,
      transaction_type: :reverse_split,
      quantity: 2,
      price: nil,
      fees: 0,
      date: Date.new(2026, 1, 4)
    )

    allow(MarketData::PriceLookupService).to receive(:new).and_return(
      instance_double(MarketData::PriceLookupService, call: nil, historical_price: nil)
    )

    get investments_portfolio_asset_detail_path(portfolio, asset)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Transferência", "Split", "Reverse Split", "Transferência entre custódias")
    expect(response.body.scan("—").size).to be >= 6
  end

  it "paginates the asset history in groups of five" do
    6.times do |index|
      Investments::Transaction.create!(
        portfolio: portfolio,
        asset: asset,
        transaction_type: :buy,
        quantity: 1,
        price: 10,
        fees: 0,
        date: Date.new(2026, 1, index + 1)
      )
    end

    allow(MarketData::PriceLookupService).to receive(:new).and_return(
      instance_double(MarketData::PriceLookupService, call: nil, historical_price: nil)
    )

    get investments_portfolio_asset_detail_path(portfolio, asset)

    expect(response.body).to include("6 movimentações", "Página 1", "history_set=5", "#transaction-history")
    expect(response.body).to include("01/01/2026", "05/01/2026")
    expect(response.body).not_to include("06/01/2026")

    get investments_portfolio_asset_detail_path(portfolio, asset), params: { history_set: 5 }

    expect(response.body).to include("Página 2", "06/01/2026", "history_set=0")
    expect(response.body).not_to include("01/01/2026")
  end

  it "groups the selected asset incomes, orders them, and calculates totals" do
    other_asset = Investments::Asset.create!(name: "Petrobras", symbol: "PETR4", category: :stock, currency: "BRL")
    Investments::Transaction.create!(
      portfolio: portfolio,
      asset: asset,
      transaction_type: :buy,
      quantity: 1,
      price: 10,
      fees: 0,
      date: Date.new(2026, 1, 1)
    )
    first_income = Investments::Income.create!(
      portfolio: portfolio,
      asset: asset,
      income_type: :dividends,
      gross_amount: 10,
      tax_amount: 1,
      payment_date: Date.new(2026, 1, 10),
      reference_date: Date.new(2025, 12, 31)
    )
    Investments::Income.create!(
      portfolio: portfolio,
      asset: asset,
      income_type: :dividends,
      gross_amount: 20,
      tax_amount: 2,
      payment_date: Date.new(2026, 2, 10)
    )
    Investments::Income.create!(
      portfolio: portfolio,
      asset: asset,
      income_type: :jcp,
      gross_amount: 5,
      tax_amount: 0,
      payment_date: Date.new(2026, 1, 20)
    )
    Investments::Income.create!(
      portfolio: portfolio,
      asset: other_asset,
      income_type: :dividends,
      gross_amount: 999,
      tax_amount: 0,
      payment_date: Date.new(2026, 1, 1)
    )
    Investments::Income.create!(
      portfolio: other_portfolio,
      asset: asset,
      income_type: :dividends,
      gross_amount: 888,
      tax_amount: 0,
      payment_date: Date.new(2026, 1, 1)
    )

    allow(MarketData::PriceLookupService).to receive(:new).and_return(
      instance_double(MarketData::PriceLookupService, call: nil, historical_price: nil)
    )

    get investments_portfolio_asset_detail_path(portfolio, asset)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Histórico de recebíveis", "Dividendos", "JCP", "Total bruto", "R$ 35,00", "R$ 3,00", "R$ 32,00")
    expect(response.body).to include("R$ 9,00", "R$ 18,00")
    expect(response.body).not_to include("R$ 999,00", "R$ 888,00", "PETR4")
    expect(response.body.index("10/01/2026")).to be < response.body.index("10/02/2026")
    expect(response.body).to include(investments_income_path(first_income))

    get investments_portfolio_asset_detail_path(portfolio, asset), params: { income_type_tab: "jcp" }

    expect(response.body).to include("JCP", "R$ 5,00")
    expect(response.body).not_to include("R$ 9,00", "R$ 18,00")
  end

  it "paginates incomes independently inside the selected type tab" do
    Investments::Transaction.create!(
      portfolio: portfolio,
      asset: asset,
      transaction_type: :buy,
      quantity: 1,
      price: 10,
      fees: 0,
      date: Date.new(2026, 1, 1)
    )
    6.times do |index|
      Investments::Income.create!(
        portfolio: portfolio,
        asset: asset,
        income_type: :dividends,
        gross_amount: index + 1,
        tax_amount: 0,
        payment_date: Date.new(2026, 3, index + 1)
      )
    end
    Investments::Income.create!(
      portfolio: portfolio,
      asset: asset,
      income_type: :jcp,
      gross_amount: 50,
      tax_amount: 0,
      payment_date: Date.new(2026, 1, 20)
    )

    allow(MarketData::PriceLookupService).to receive(:new).and_return(
      instance_double(MarketData::PriceLookupService, call: nil, historical_price: nil)
    )

    get investments_portfolio_asset_detail_path(portfolio, asset), params: { income_type_tab: "dividends", income_history_set: 5 }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Dividendos", "Página 2", "06/03/2026", "R$ 6,00", "#income-history")
    expect(response.body).not_to include("01/03/2026")
  end

  it "renders a clear empty state when the asset has no income records" do
    Investments::Transaction.create!(
      portfolio: portfolio,
      asset: asset,
      transaction_type: :buy,
      quantity: 1,
      price: 10,
      fees: 0,
      date: Date.new(2026, 1, 1)
    )

    allow(MarketData::PriceLookupService).to receive(:new).and_return(
      instance_double(MarketData::PriceLookupService, call: nil, historical_price: nil)
    )

    get investments_portfolio_asset_detail_path(portfolio, asset)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Nenhum recebimento encontrado para este ativo nesta carteira.")
    expect(response.body).not_to include("Tipos de recebíveis")
  end
end
