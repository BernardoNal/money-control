require "digest"

module Transactions
  module Imports
    class DuplicateDetector
      SEPARATOR = "\u001f"

      def self.annotate(account:, rows:)
        new(account: account, rows: rows).annotate
      end

      def initialize(account:, rows:)
        @account = account
        @rows = rows
      end

      def annotate
        seen = {}

        rows.map do |row|
          next row unless row["status"] == "valid"

          fingerprint = fingerprint_for(row)
          reason = if seen[fingerprint]
                     "Repete a linha #{seen[fingerprint]} deste arquivo."
                   elsif existing_transaction?(fingerprint)
                     "Já existe uma transação importada igual nesta conta."
                   end

          seen[fingerprint] ||= row["line_number"]
          row.merge(
            "import_fingerprint" => fingerprint,
            "possible_duplicate" => reason.present?,
            "duplicate_reason" => reason,
            "selected" => reason.blank?
          )
        end
      end

      private

      attr_reader :account, :rows

      def fingerprint_for(row)
        Digest::SHA256.hexdigest(
          [
            account.id,
            row["date"],
            row["amount"],
            normalize(row["description"]),
            normalize(row["to_whom"]),
            normalize(row["payment_method"]),
            normalize(row["document_number"])
          ].join(SEPARATOR)
        )
      end

      def existing_transaction?(fingerprint)
        account.transactions.where(import_fingerprint: fingerprint).exists?
      end

      def normalize(value)
        value.to_s.strip.downcase
      end
    end
  end
end
