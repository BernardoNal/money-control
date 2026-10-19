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
        seen_fingerprints = {}
        seen_source_identifiers = {}

        rows.map do |row|
          next row unless row["status"] == "valid"

          fingerprint = fingerprint_for(row)
          source_identifier = normalize(row["source_identifier"])
          duplicate_type, reason = duplicate_for(
            row: row,
            fingerprint: fingerprint,
            source_identifier: source_identifier,
            seen_fingerprints: seen_fingerprints,
            seen_source_identifiers: seen_source_identifiers
          )

          seen_fingerprints[fingerprint] ||= row["line_number"]
          seen_source_identifiers[source_identifier] ||= row["line_number"] if source_identifier.present?
          row.merge(
            "import_fingerprint" => fingerprint,
            "possible_duplicate" => duplicate_type == "possible",
            "confirmed_duplicate" => duplicate_type == "confirmed",
            "duplicate_type" => duplicate_type,
            "duplicate_reason" => reason,
            "selected" => reason.blank?
          )
        end
      end

      private

      attr_reader :account, :rows

      def duplicate_for(row:, fingerprint:, source_identifier:, seen_fingerprints:, seen_source_identifiers:)
        if source_identifier.present?
          return ["confirmed", "Repete o identificador da linha #{seen_source_identifiers[source_identifier]} deste arquivo."] if seen_source_identifiers[source_identifier]
          return ["confirmed", "Já existe uma transação importada com este identificador nesta conta."] if existing_source_identifier?(source_identifier)
          return ["possible", "Já existe uma transação semelhante nesta conta."] if existing_transaction?(row, fingerprint)
        else
          return ["possible", "Repete a linha #{seen_fingerprints[fingerprint]} deste arquivo."] if seen_fingerprints[fingerprint]
          return ["possible", "Já existe uma transação semelhante nesta conta."] if existing_transaction?(row, fingerprint)
        end

        [nil, nil]
      end

      def fingerprint_for(row)
        # The fingerprint includes the account so a transaction from another
        # account is never treated as a duplicate, even when the other values match.
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

      def existing_transaction?(row, fingerprint)
        return true if account.transactions.where(import_fingerprint: fingerprint).exists?

        # Older or manually created transactions may not have import metadata;
        # compare their persisted attributes as a backward-compatible fallback.
        account.transactions.where(date: row["date"], amount: row["amount"]).any? do |transaction|
          [
            [transaction.description, row["description"]],
            [transaction.to_whom, row["to_whom"]],
            [transaction.payment_method, row["payment_method"]],
            [transaction.source_document_number, row["document_number"]]
          ].all? { |stored, incoming| normalize(stored) == normalize(incoming) }
        end
      end

      def existing_source_identifier?(source_identifier)
        account.transactions.where(source_identifier: source_identifier).exists?
      end

      def normalize(value)
        value.to_s.strip.downcase
      end
    end
  end
end
