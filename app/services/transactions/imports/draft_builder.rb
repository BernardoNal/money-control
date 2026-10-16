module Transactions
  module Imports
    class DraftBuilder
      def self.build(account:, filename:, result:)
        rows = result.rows.map { |row| serialize_row(row) }

        TransactionImport.new(
          account: account,
          original_filename: filename,
          rows: rows,
          summary: summary_for(rows),
          expires_at: 1.hour.from_now
        )
      end

      def self.apply_categories!(transaction_import:, selections:, categories:)
        categories_by_id = categories.index_by { |category| category.id.to_s }
        invalid_category_ids = []

        rows = transaction_import.rows.map do |row|
          next row unless row["status"] == "valid"

          category_id = selections[row["line_number"].to_s].presence
          if category_id.present? && categories_by_id.key?(category_id)
            row.merge(
              "category_id" => category_id.to_i,
              "category_name" => categories_by_id.fetch(category_id).name
            )
          else
            invalid_category_ids << category_id if category_id.present?
            row.merge("category_id" => nil, "category_name" => nil)
          end
        end

        [rows, invalid_category_ids.compact.uniq]
      end

      def self.serialize_row(row)
        {
          "line_number" => row.line_number,
          "date" => row.date&.iso8601,
          "amount" => row.amount&.to_s("F"),
          "description" => row.description,
          "category_name" => row.category_name,
          "category_id" => nil,
          "to_whom" => row.to_whom,
          "document_number" => row.document_number,
          "transaction_type" => row.transaction_type,
          "payment_method" => row.payment_method,
          "status" => row.status.to_s,
          "errors" => row.errors,
          "ignored_reason" => row.ignored_reason
        }
      end
      private_class_method :serialize_row

      def self.summary_for(rows)
        rows.group_by { |row| row["status"] }.transform_values(&:size)
      end
      private_class_method :summary_for
    end
  end
end
