require "json"
require "net/http"

module MarketData
  module Providers
    class BrapiProvider < Provider
      BASE_URL = "https://brapi.dev/api/v2".freeze
      API_TOKEN_ENV = "BRAPI_API_TOKEN".freeze

      def initialize(api_token: ENV[API_TOKEN_ENV])
        @api_token = api_token
      end

      def lookup_asset(symbol:)
        payload = fetch_asset_metadata(symbol: symbol)
        metadata = payload

        AssetData.new(
          symbol: payload.fetch("symbol", symbol),
          name: metadata["longName"].presence || metadata["name"].presence || payload.fetch("symbol", symbol),
          currency: metadata["currency"],
          category: map_category(metadata),
          subcategory: nil,
          active: active_from(metadata)
        )
      end

      def fetch_asset_metadata(symbol:)
        payload = get_json(
          path: "/tickers",
          query_params: { search: symbol }
        )

        results = payload.fetch("results", [])
        asset_payload = results.find do |item|
          item["symbol"].to_s.casecmp?(symbol)
        end

        raise NotFoundError, "Asset not found for symbol #{symbol}" if asset_payload.blank?
        raise NotFoundError, "Asset not found for symbol #{symbol}" if asset_payload["longName"].blank? && asset_payload["name"].blank?

        asset_payload
      end

      def fetch_price(symbol:)
        payload = get_json(
          path: "/stocks/quote",
          query_params: { symbols: symbol }
        )
        quote = payload.fetch("results", []).find do |item|
          item["symbol"].to_s.casecmp?(symbol)
        end
        price_payload = quote&.fetch("data", {}) || {}

        raise NotFoundError, "Price not found for symbol #{symbol}" if quote.blank?
        raise NotFoundError, "Price not found for symbol #{symbol}" if price_payload["regularMarketPrice"].blank?

        PriceData.new(
          symbol: quote.fetch("symbol", symbol),
          price: BigDecimal(price_payload.fetch("regularMarketPrice").to_s),
          currency: price_payload["currency"],
          as_of: parse_time(price_payload["regularMarketTime"])
        )
      end

      private

      attr_reader :api_token

      def get_json(path:, query_params:)
        uri = URI("#{BASE_URL}#{path}")
        uri.query = URI.encode_www_form(query_params) if query_params.present?

        request = Net::HTTP::Get.new(uri)
        request["Authorization"] = "Bearer #{api_token}" if api_token.present?

        response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |http|
          http.request(request)
        end

        unless response.code.to_i.between?(200, 299)
          raise ProviderError, "BRAPI request failed with status #{response.code}"
        end

        payload = JSON.parse(response.body)
        raise ProviderError, payload["error"] if payload["error"].present?

        payload
      rescue JSON::ParserError => e
        raise ProviderError, "BRAPI returned invalid JSON: #{e.message}"
      end

      def map_category(metadata)
        asset_type = metadata["assetType"].to_s.downcase
        sub_type = metadata["subType"].to_s.downcase
        currency = metadata["currency"].to_s.upcase

        return "etf" if sub_type == "etf"
        return "fii" if sub_type == "fii"
        return "crypto" if asset_type.include?("crypto")
        return "fixed_income" if sub_type.include?("fi-infra") || sub_type.include?("fi-agro")
        return "stock" if asset_type == "stock" && currency == "BRL"
        return "international" if asset_type == "stock"
        return "international" if asset_type == "bdr"
        return "etf" if asset_type == "fund" && sub_type == "etf"

        nil
      end

      def active_from(metadata)
        metadata["isActive"].nil? ? (metadata["longName"].present? || metadata["name"].present?) : metadata["isActive"]
      end

      def parse_time(value)
        return if value.blank?

        Time.zone.parse(value.to_s)
      rescue ArgumentError
        nil
      end
    end
  end
end
