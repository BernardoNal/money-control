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
      instance_double(MarketData::PriceLookupService, call: MarketData::PriceData.new(symbol: asset.symbol, price: 12, currency: asset.currency, as_of: Time.current))
    )

    get investments_portfolio_asset_detail_path(portfolio, asset)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("AAPL34", "Resultado não realizado", "R$ 24,00", "R$ 4,00")
  end
end
