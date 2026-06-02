require "rails_helper"

RSpec.describe "Investments::Assets", type: :request do
  let(:user) do
    User.create!(
      name: "Asset User",
      email: "asset-user@example.com",
      password: "password123"
    )
  end

  let!(:stock_asset) do
    Investments::Asset.create!(
      name: "Apple Inc.",
      symbol: "AAPL",
      category: :international,
      currency: "USD",
      active: true
    )
  end

  let!(:crypto_asset) do
    Investments::Asset.create!(
      name: "Bitcoin",
      symbol: "BTC",
      category: :crypto,
      currency: "USD",
      active: true
    )
  end

  before do
    sign_in user
  end

  describe "GET /index" do
    it "renders the asset listing" do
      get investments_assets_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Ativos")
      expect(response.body).to include("AAPL")
      expect(response.body).to include("BTC")
    end

    it "filters assets by category" do
      get investments_assets_path, params: { category: "crypto" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("BTC")
      expect(response.body).not_to include("AAPL")
    end
  end

  describe "GET /show" do
    it "renders the selected asset" do
      get investments_asset_path(stock_asset)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Apple Inc.")
      expect(response.body).to include("International")
    end
  end

  describe "POST /create" do
    it "creates an asset with category support" do
      expect do
        post investments_assets_path, params: {
          investments_asset: {
            name: "XP Malls",
            symbol: "XPML11",
            category: "fii",
            currency: "BRL",
            active: "1"
          }
        }
      end.to change(Investments::Asset, :count).by(1)

      asset = Investments::Asset.order(:created_at).last
      expect(response).to redirect_to(investments_asset_path(asset))
      expect(asset.category).to eq("fii")
    end
  end

  describe "PATCH /update" do
    it "updates the asset category without creating a new record" do
      expect do
        patch investments_asset_path(stock_asset), params: {
          investments_asset: {
            category: "stock",
            currency: "BRL"
          }
        }
      end.not_to change(Investments::Asset, :count)

      expect(response).to redirect_to(investments_asset_path(stock_asset))

      stock_asset.reload
      expect(stock_asset.category).to eq("stock")
      expect(stock_asset.currency).to eq("BRL")
    end
  end
end
