require "rails_helper"

RSpec.describe MarketData::Providers::BrapiProvider do
  subject(:provider) { described_class.new(api_token: "test-token", max_symbols_per_request: 2) }

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

    it "uses the issuer name for BDRs instead of the provider technical description" do
      response = instance_double(
        Net::HTTPOK,
        code: "200",
        body: {
          "results" => [
            {
              "symbol" => "A1MD34",
              "shortName" => "A1MD34",
              "name" => "Advanced Micro Devices, Inc.",
              "longName" => "Advanced Micro Devices, Inc. Shs Unsponsored Brazilian Depositary Receipt Repr 0.05 Sh",
              "assetType" => "bdr",
              "currency" => "BRL",
              "isActive" => true
            }
          ]
        }.to_json
      )

      expect_request(response, "A1MD34")

      result = provider.lookup_asset(symbol: "A1MD34")

      expect(result).to eq(
        MarketData::AssetData.new(
          symbol: "A1MD34",
          name: "Advanced Micro Devices, Inc.",
          currency: "BRL",
          category: "international",
          subcategory: nil,
          active: true
        )
      )
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

  describe "#fetch_prices" do
    it "returns available prices for a normalized batch" do
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
            },
            {
              "symbol" => "VALE3",
              "data" => {
                "currency" => "BRL",
                "regularMarketPrice" => 61.2,
                "regularMarketTime" => "2026-07-13T10:00:00.000Z"
              }
            }
          ]
        }.to_json
      )

      expect_batch_quote_request(response, ["PETR4", "VALE3"])

      result = provider.fetch_prices(symbols: [" petr4 ", "VALE3", "PETR4"])

      expect(result.map(&:symbol)).to eq(["PETR4", "VALE3"])
      expect(result.map(&:price)).to eq([BigDecimal("32.15"), BigDecimal("61.2")])
    end

    it "skips quotes without a current price" do
      response = instance_double(
        Net::HTTPOK,
        code: "200",
        body: {
          "results" => [
            {
              "symbol" => "PETR4",
              "data" => { "currency" => "BRL", "regularMarketPrice" => 32.15 }
            },
            { "symbol" => "VALE3", "data" => { "currency" => "BRL" } }
          ]
        }.to_json
      )

      expect_batch_quote_request(response, ["PETR4", "VALE3"])

      result = provider.fetch_prices(symbols: ["PETR4", "VALE3"])

      expect(result.map(&:symbol)).to eq(["PETR4"])
    end

    it "does not request the provider for an empty batch" do
      expect(Net::HTTP).not_to receive(:start)

      expect(provider.fetch_prices(symbols: [" ", nil])).to eq([])
    end
  end

  describe "configuration" do
    it "uses one symbol per request by default" do
      single_symbol_provider = described_class.new(api_token: "test-token")
      responses = [
        instance_double(Net::HTTPOK, code: "200", body: { "results" => [{ "symbol" => "PETR4", "data" => { "regularMarketPrice" => 32.15 } }] }.to_json),
        instance_double(Net::HTTPOK, code: "200", body: { "results" => [{ "symbol" => "VALE3", "data" => { "regularMarketPrice" => 61.2 } }] }.to_json)
      ]
      expect_batch_quote_requests(responses, [["PETR4"], ["VALE3"]])

      result = single_symbol_provider.fetch_prices(symbols: ["PETR4", "VALE3"])

      expect(result.map(&:symbol)).to eq(["PETR4", "VALE3"])
    end

    it "splits symbols according to a configured request limit" do
      configured_provider = described_class.new(api_token: "test-token", max_symbols_per_request: 2)
      responses = [
        instance_double(Net::HTTPOK, code: "200", body: { "results" => [{ "symbol" => "PETR4", "data" => { "regularMarketPrice" => 32.15 } }, { "symbol" => "XPML11", "data" => { "regularMarketPrice" => 11.0 } }] }.to_json),
        instance_double(Net::HTTPOK, code: "200", body: { "results" => [{ "symbol" => "VALE3", "data" => { "regularMarketPrice" => 61.2 } }] }.to_json)
      ]
      expect_batch_quote_requests(responses, [["PETR4", "XPML11"], ["VALE3"]])

      result = configured_provider.fetch_prices(symbols: ["PETR4", "XPML11", "VALE3"])

      expect(result.map(&:symbol)).to eq(["PETR4", "XPML11", "VALE3"])
    end

    it "keeps valid prices from other batches when one quote is unavailable" do
      configured_provider = described_class.new(api_token: "test-token", max_symbols_per_request: 2)
      responses = [
        instance_double(Net::HTTPOK, code: "200", body: { "results" => [{ "symbol" => "PETR4", "data" => { "regularMarketPrice" => 32.15 } }, { "symbol" => "XPML11", "data" => {} }] }.to_json),
        instance_double(Net::HTTPOK, code: "200", body: { "results" => [{ "symbol" => "VALE3", "data" => { "regularMarketPrice" => 61.2 } }] }.to_json)
      ]
      expect_batch_quote_requests(responses, [["PETR4", "XPML11"], ["VALE3"]])

      result = configured_provider.fetch_prices(symbols: ["PETR4", "XPML11", "VALE3"])

      expect(result.map(&:symbol)).to eq(["PETR4", "VALE3"])
    end

    it "keeps valid prices when another batch fails at the provider" do
      configured_provider = described_class.new(api_token: "test-token", max_symbols_per_request: 1)
      responses = [
        instance_double(Net::HTTPOK, code: "200", body: { "results" => [{ "symbol" => "PETR4", "data" => { "regularMarketPrice" => 32.15 } }] }.to_json),
        MarketData::ProviderError.new("BRAPI request failed with status 429"),
        instance_double(Net::HTTPOK, code: "200", body: { "results" => [{ "symbol" => "VALE3", "data" => { "regularMarketPrice" => 61.2 } }] }.to_json)
      ]
      expect_batch_quote_requests(responses, [["PETR4"], ["XPML11"], ["VALE3"]])

      result = configured_provider.fetch_prices(symbols: ["PETR4", "XPML11", "VALE3"])

      expect(result.map(&:symbol)).to eq(["PETR4", "VALE3"])
    end

    it "keeps valid prices when another batch times out" do
      configured_provider = described_class.new(api_token: "test-token", max_symbols_per_request: 1)
      responses = [
        instance_double(Net::HTTPOK, code: "200", body: { "results" => [{ "symbol" => "PETR4", "data" => { "regularMarketPrice" => 32.15 } }] }.to_json),
        Net::ReadTimeout.new("request timed out"),
        instance_double(Net::HTTPOK, code: "200", body: { "results" => [{ "symbol" => "VALE3", "data" => { "regularMarketPrice" => 61.2 } }] }.to_json)
      ]
      expect_batch_quote_requests(responses, [["PETR4"], ["XPML11"], ["VALE3"]])

      result = configured_provider.fetch_prices(symbols: ["PETR4", "XPML11", "VALE3"])

      expect(result.map(&:symbol)).to eq(["PETR4", "VALE3"])
    end

    it "rejects a non-positive or invalid request limit" do
      expect { described_class.new(max_symbols_per_request: 0) }
        .to raise_error(ArgumentError, /BRAPI_MAX_SYMBOLS_PER_REQUEST/)
      expect { described_class.new(max_symbols_per_request: "invalid") }
        .to raise_error(ArgumentError, /BRAPI_MAX_SYMBOLS_PER_REQUEST/)
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

  def expect_batch_quote_request(response, symbols)
    allow(Net::HTTP).to receive(:start) do |hostname, port, use_ssl:, &block|
      expect(hostname).to eq("brapi.dev")
      expect(port).to eq(443)
      expect(use_ssl).to be(true)

      http = instance_double("Net::HTTP")
      expect(http).to receive(:request) do |request|
        expect(request.path).to eq("/api/v2/stocks/quote?symbols=#{symbols.join("%2C")}")
        expect(request["Authorization"]).to eq("Bearer test-token")
        response
      end

      block.call(http)
    end
  end

  def expect_batch_quote_requests(responses, batches)
    allow(Net::HTTP).to receive(:start).exactly(batches.size).times do |hostname, port, use_ssl:, &block|
      expect(hostname).to eq("brapi.dev")
      expect(port).to eq(443)
      expect(use_ssl).to be(true)

      http = instance_double("Net::HTTP")
      expected_symbols = batches.shift
      expect(http).to receive(:request) do |request|
        expect(request.path).to eq("/api/v2/stocks/quote?symbols=#{expected_symbols.join("%2C")}")
        expect(request["Authorization"]).to eq("Bearer test-token")
        response = responses.shift
        raise response if response.is_a?(Exception)

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
