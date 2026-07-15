require "rails_helper"

RSpec.describe MarketData::Providers::BrapiProvider do
  subject(:provider) { described_class.new(api_token: "test-token") }

  describe "#lookup_asset" do
    it "returns normalized asset metadata for a Brazilian stock" do
      response = instance_double(
        Net::HTTPOK,
        code: "200",
        body: {
          "results" => [
            {
              "symbol" => "PETR4",
              "name" => "PETROLEO BRASILEIRO S.A. PETROBRAS",
              "longName" => "Petroleo Brasileiro SA Pfd",
              "assetType" => "stock",
              "subType" => "stock",
              "exchange" => "B3",
              "currency" => "BRL",
              "sector" => "Energy Minerals",
              "isActive" => true
            }
          ]
        }.to_json
      )

      expect_request(response, "PETR4")

      result = provider.lookup_asset(symbol: "PETR4")

      expect(result).to eq(
        MarketData::AssetData.new(
          symbol: "PETR4",
          name: "Petroleo Brasileiro SA Pfd",
          currency: "BRL",
          category: "stock",
          subcategory: nil,
          active: true
        )
      )
    end

    it "maps ETFs when BRAPI exposes the quote type" do
      response = instance_double(
        Net::HTTPOK,
        code: "200",
        body: {
          "results" => [
            {
              "symbol" => "IVVB11",
              "name" => "IVVB11",
              "longName" => "iShares S&P 500 Fundo de Investimento em Cotas de Fundo de Indice - Investimento no Exterior",
              "assetType" => "fund",
              "subType" => "etf",
              "exchange" => "B3",
              "currency" => "BRL",
              "sector" => "Miscellaneous",
              "isActive" => true
            }
          ]
        }.to_json
      )

      expect_request(response, "IVVB11")

      result = provider.lookup_asset(symbol: "IVVB11")

      expect(result.category).to eq("etf")
    end
  end

  describe "#fetch_asset_metadata" do
    it "raises not found when BRAPI returns no matching asset" do
      response = instance_double(Net::HTTPOK, code: "200", body: { "results" => [] }.to_json)
      expect_request(response, "UNKNOWN")

      expect { provider.fetch_asset_metadata(symbol: "UNKNOWN") }
        .to raise_error(MarketData::NotFoundError, "Asset not found for symbol UNKNOWN")
    end

    it "raises provider error when the response status is not successful" do
      response = instance_double(Net::HTTPTooManyRequests, code: "429", body: "")
      expect_request(response, "PETR4")

      expect { provider.fetch_asset_metadata(symbol: "PETR4") }
        .to raise_error(MarketData::ProviderError, "BRAPI request failed with status 429")
    end

    it "raises provider error when the payload contains a provider error" do
      response = instance_double(
        Net::HTTPOK,
        code: "200",
        body: { "error" => "Rate limit exceeded" }.to_json
      )
      expect_request(response, "PETR4")

      expect { provider.fetch_asset_metadata(symbol: "PETR4") }
        .to raise_error(MarketData::ProviderError, "Rate limit exceeded")
    end
  end

  describe "#fetch_price" do
    it "returns normalized market price data for a quoted asset" do
      response = instance_double(
        Net::HTTPOK,
        code: "200",
        body: {
          "results" => [
            {
              "symbol" => "PETR4",
              "data" => {
                "currency" => "BRL",
                "regularMarketPrice" => 32.15,
                "regularMarketTime" => "2026-07-13T10:00:00.000Z"
              }
            }
          ]
        }.to_json
      )

      expect_quote_request(response, "PETR4")

      result = provider.fetch_price(symbol: "PETR4")

      expect(result).to eq(
        MarketData::PriceData.new(
          symbol: "PETR4",
          price: BigDecimal("32.15"),
          currency: "BRL",
          as_of: Time.zone.parse("2026-07-13T10:00:00Z")
        )
      )
    end

    it "raises not found when BRAPI returns no current price" do
      response = instance_double(
        Net::HTTPOK,
        code: "200",
        body: { "results" => [{ "symbol" => "PETR4", "data" => { "currency" => "BRL" } }] }.to_json
      )
      expect_quote_request(response, "PETR4")

      expect { provider.fetch_price(symbol: "PETR4") }
        .to raise_error(MarketData::NotFoundError, "Price not found for symbol PETR4")
    end
  end

  def expect_request(response, symbol)
    allow(Net::HTTP).to receive(:start) do |hostname, port, use_ssl:, &block|
      expect(hostname).to eq("brapi.dev")
      expect(port).to eq(443)
      expect(use_ssl).to be(true)

      http = instance_double("Net::HTTP")
      expect(http).to receive(:request) do |request|
        expect(request.path).to include("/api/v2/tickers")
        expect(request.path).to include("search=#{symbol}")
        expect(request["Authorization"]).to eq("Bearer test-token")
        response
      end

      block.call(http)
    end
  end

  def expect_quote_request(response, symbol)
    allow(Net::HTTP).to receive(:start) do |hostname, port, use_ssl:, &block|
      expect(hostname).to eq("brapi.dev")
      expect(port).to eq(443)
      expect(use_ssl).to be(true)

      http = instance_double("Net::HTTP")
      expect(http).to receive(:request) do |request|
        expect(request.path).to eq("/api/v2/stocks/quote?symbols=#{symbol}")
        expect(request["Authorization"]).to eq("Bearer test-token")
        response
      end

      block.call(http)
    end
  end
end
