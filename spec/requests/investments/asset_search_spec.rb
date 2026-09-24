require "rails_helper"

RSpec.describe "Investments::AssetSearch", type: :request do
  let(:user) do
    User.create!(name: "Search User", email: "search-user@example.com", password: "password123")
  end

  before do
    sign_in user
  end

  describe "GET /investments/assets/search" do
    it "returns a limited list matching the symbol prefix" do
      21.times do |index|
        Investments::Asset.create!(
          name: "Apple #{index}",
          symbol: "AAPL#{index}",
          category: :international,
          currency: "USD"
        )
      end

      get search_investments_assets_path, params: { q: "AAPL" }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.size).to eq(20)
      expect(response.parsed_body.first).to include("symbol" => "AAPL0", "name" => "Apple 0")
    end

    it "filters inactive assets when requested" do
      active_asset = Investments::Asset.create!(name: "Active Asset", symbol: "ACT1", category: :stock, currency: "BRL", active: true)
      Investments::Asset.create!(name: "Inactive Asset", symbol: "ACT2", category: :stock, currency: "BRL", active: false)

      get search_investments_assets_path, params: { q: "ACT", active_only: "true" }

      expect(response.parsed_body.map { |asset| asset["id"] }).to eq([active_asset.id])
    end

    it "requires authentication" do
      sign_out user

      get search_investments_assets_path, params: { q: "AAPL" }

      expect(response).to redirect_to(new_user_session_path)
    end

    it "returns no assets for an empty query" do
      Investments::Asset.create!(name: "Apple", symbol: "AAPL", category: :international, currency: "USD")

      get search_investments_assets_path, params: { q: "" }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq([])
    end
  end
end
