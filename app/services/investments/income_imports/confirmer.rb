require "date"

module Investments
  module IncomeImports
    class Confirmer
      Result = Struct.new(:success?, :message, :created_count, keyword_init: true)

      def self.call(income_import:)
        new(income_import: income_import).call
      end

      def initialize(income_import:)
        @income_import = income_import
      end

      def call
        return failure("Esta importação já foi confirmada.") unless income_import.pending?
        return expire_import if expired?

        rows = income_import.rows.select { |row| row["status"] == "valid" }
        return failure("Não há recebíveis válidos selecionados para importar.") if rows.empty?
        return failure(duplicate_message(rows)) if rows.any? { |row| row["duplicate_type"].present? }

        created_count = 0
        # The draft and all generated incomes must change together. A single
        # invalid row must never leave the portfolio partially imported.
        ActiveRecord::Base.transaction do
          rows.each do |row|
            Investments::Income.create!(income_attributes(row))
            created_count += 1
          end
          income_import.update!(status: "completed", completed_at: Time.current)
        end

        success("Importação concluída com #{created_count} recebível(is).", created_count)
      rescue ActiveRecord::RecordInvalid => e
        failure("A importação não foi concluída: #{e.record.errors.full_messages.to_sentence}")
      end

      private

      attr_reader :income_import

      def income_attributes(row)
        gross_amount = row["amount"].to_d
        tax_amount = tax_amount_for(row)
        payment_date = parse_date(row["settlement_date"].presence || row["movement_date"])
        raise ActiveRecord::RecordInvalid, "Valor e data são obrigatórios." if gross_amount <= 0 || payment_date.nil?

        {
          portfolio: income_import.portfolio,
          asset_id: row["asset_id"],
          income_type: row["classification"],
          gross_amount: gross_amount,
          tax_amount: tax_amount,
          payment_date: payment_date,
          reference_date: parse_date(row["movement_date"]),
          notes: row["description"]
        }
      end

      def tax_amount_for(row)
        return 0.to_d unless row["paired_line_number"]

        # Brokerage files report securities-lending income and its donor fee
        # as separate movements; the fee becomes tax on the single income.
        tax_row = income_import.rows.find do |candidate|
          candidate["line_number"].to_s == row["paired_line_number"].to_s && candidate["pair_role"] == "tax"
        end
        tax_row ? tax_row["amount"].to_d.abs : 0.to_d
      end

      def parse_date(value)
        Date.iso8601(value.to_s) if value.present?
      rescue Date::Error
        nil
      end

      def duplicate_message(rows)
        lines = rows.filter_map { |row| row["line_number"] if row["duplicate_type"].present? }
        "Revise as possíveis duplicidades antes de confirmar (linhas: #{lines.join(", ")})."
      end

      def expired?
        income_import.expires_at.present? && income_import.expires_at <= Time.current
      end

      def expire_import
        income_import.update!(status: "expired")
        failure("Esta importação expirou. Envie o arquivo novamente.")
      end

      def success(message, created_count)
        Result.new(success?: true, message: message, created_count: created_count)
      end

      def failure(message)
        Result.new(success?: false, message: message, created_count: 0)
      end
    end
  end
end
