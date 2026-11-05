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

    expect(response.body).to include("6 movimentações", "Página 1", "history_set=5")
    expect(response.body).to include("01/01/2026", "05/01/2026")
    expect(response.body).not_to include("06/01/2026")

    get investments_portfolio_asset_detail_path(portfolio, asset), params: { history_set: 5 }

    expect(response.body).to include("Página 2", "06/01/2026", "history_set=0")
    expect(response.body).not_to include("01/01/2026")
  end
end
