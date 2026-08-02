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

  describe "POST /create" do
    it "creates an asset by auto-filling fields from the market data provider" do
      asset_data = MarketData::AssetData.new(
        symbol: "PETR4",
        name: "Petroleo Brasileiro SA Pfd",
        currency: "BRL",
        category: "stock",
        subcategory: nil,
        active: true
      )

      lookup_service = instance_double(MarketData::AssetLookupService, call: asset_data)
      allow(MarketData::AssetLookupService).to receive(:new).and_return(lookup_service)

      expect do
        post investments_assets_path, params: {
          investments_asset: {
            name: "",
            symbol: "PETR4",
            category: "",
            subcategory: "",
            currency: ""
          }
        }
      end.to change(Investments::Asset, :count).by(1)

      asset = Investments::Asset.order(:created_at).last
      expect(response).to redirect_to(edit_investments_asset_path(asset))
      expect(asset.name).to eq("Petroleo Brasileiro SA Pfd")
      expect(asset.category).to eq("stock")
      expect(asset.currency).to eq("BRL")
      expect(asset.active).to be(true)
      expect(lookup_service).to have_received(:call).with(symbol: "PETR4")
    end

    it "renders the form with an error when the ticker is not found" do
      lookup_service = instance_double(MarketData::AssetLookupService)
      allow(MarketData::AssetLookupService).to receive(:new).and_return(lookup_service)
      allow(lookup_service).to receive(:call).and_raise(MarketData::NotFoundError, "missing")

      expect do
        post investments_assets_path, params: {
          investments_asset: {
            name: "",
            symbol: "INVALIDO",
            category: "",
            subcategory: "",
            currency: ""
          }
        }
      end.not_to change(Investments::Asset, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Ticker / Simbolo nao foi encontrado no provedor de mercado")
    end

    it "creates an asset with category support" do
      expect do
        post investments_assets_path, params: {
          investments_asset: {
            name: "XP Malls",
            symbol: "XPML11",
            category: "fii",
            subcategory: "shopping_malls",
            currency: "BRL",
            active: "1"
          }
        }
      end.to change(Investments::Asset, :count).by(1)

      asset = Investments::Asset.order(:created_at).last
      expect(response).to redirect_to(edit_investments_asset_path(asset))
      expect(asset.category).to eq("fii")
    end

    it "rejects incompatible category and subcategory combinations" do
      expect do
        post investments_assets_path, params: {
          investments_asset: {
            name: "Petrobras",
            symbol: "PETR4-MANUAL",
            category: "stock",
            subcategory: "paper",
            currency: "BRL",
            active: "1"
          }
        }
      end.not_to change(Investments::Asset, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("SubCategoria não é compatível com a categoria selecionada")
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

      expect(response).to redirect_to(edit_investments_asset_path(stock_asset))

      stock_asset.reload
      expect(stock_asset.category).to eq("stock")
      expect(stock_asset.currency).to eq("BRL")
    end
  end
end
