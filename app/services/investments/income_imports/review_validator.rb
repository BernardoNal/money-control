require "date"

module Investments
  module IncomeImports
    class ReviewValidator
      Result = Struct.new(:rows, :errors, keyword_init: true)

      def self.call(portfolio:, rows:)
        new(portfolio: portfolio, rows: rows).call
      end

      def initialize(portfolio:, rows:)
        @portfolio = portfolio
        @rows = rows
      end

      def call
        seen = {}
        errors = []
        rows = @rows.map do |row|
          next row unless row["status"] == "valid"

          classification = row["classification"]
          asset = asset_for(row)
          date = payment_date_for(row)
          errors << "Selecione um tipo de provento para a linha #{row["line_number"]}." unless Investments::Income.income_types.key?(classification)
          errors << "Selecione um ativo válido para a linha #{row["line_number"]}." unless asset
          errors << "A data da linha #{row["line_number"]} é inválida." unless date

          annotated = annotate_duplicate(row, asset: asset, date: date, seen: seen)
          annotated.merge("requires_review" => annotated["requires_review"] || annotated["duplicate_type"] == "possible")
        end

        Result.new(rows: rows, errors: errors)
      end

      private

      def asset_for(row)
        Investments::Asset.find_by(id: row["asset_id"])
      end

      def payment_date_for(row)
        value = row["settlement_date"].presence || row["movement_date"].presence
        Date.iso8601(value) if value
      rescue Date::Error
        nil
      end

      def annotate_duplicate(row, asset:, date:, seen:)
        return row unless asset && date && Investments::Income.income_types.key?(row["classification"])

        fingerprint = [asset.id, row["classification"], date.iso8601]
        amount = row["amount"].to_d
        previous = seen[fingerprint]
        duplicate_type = if previous && previous.to_d == amount
                           "confirmed"
                         elsif previous
                           "possible"
                         else
                           duplicate_for_existing(fingerprint: fingerprint, amount: amount)
                         end
        seen[fingerprint] = amount
        return row unless duplicate_type

        row.merge(
          "duplicate_type" => duplicate_type,
          "possible_duplicate" => duplicate_type == "possible",
          "confirmed_duplicate" => duplicate_type == "confirmed",
          "duplicate_reason" => duplicate_reason(duplicate_type)
        )
      end

      def duplicate_for_existing(fingerprint:, amount:)
        asset_id, classification, date = fingerprint
        income_type = Investments::Income.income_types.fetch(classification)
        relation = @portfolio.incomes.where(asset_id: asset_id, income_type: income_type, payment_date: date)
        return nil unless relation.exists?

        relation.where(gross_amount: amount).exists? ? "confirmed" : "possible"
      end

      def duplicate_reason(type)
        return "Repete um recebível já existente ou repetido no arquivo." if type == "confirmed"

        "Tem a mesma carteira, ativo, tipo e data de outro recebível, mas valor diferente."
      end
    end
  end
end
