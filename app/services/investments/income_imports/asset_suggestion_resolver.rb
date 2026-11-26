module Investments
  module IncomeImports
    class AssetSuggestionResolver
      def self.call(assets:)
        new(assets: assets).call
      end

      def initialize(assets:)
        @assets = assets
      end

      def call
        assets.group_by { |asset| issuer_key(asset.symbol) }.each_with_object({}) do |(issuer, matches), suggestions|
          # Never choose between share classes or depositary receipts silently.
          suggestions[issuer] = matches.first if issuer.present? && matches.one?
        end
      end

      private

      attr_reader :assets

      def issuer_key(symbol)
        symbol.to_s.upcase.sub(/\d+\z/, "")
      end
    end
  end
end
