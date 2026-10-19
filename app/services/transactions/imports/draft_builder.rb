module Transactions
  module Imports
    class DraftBuilder
      def self.build(account:, filename:, result:, default_categories:)
        rows = DuplicateDetector.annotate(
          account: account,
          rows: result.rows.map { |row| serialize_row(row, default_categories) }
        )

        TransactionImport.new(
          account: account,
          original_filename: filename,
          rows: rows,
          summary: summary_for(rows),
          expires_at: 1.hour.from_now
        )
      end

      def self.apply_categories!(transaction_import:, selections:, selected_lines:, descriptions:, categories:, default_categories:)
        categories_by_id = categories.index_by { |category| category.id.to_s }
        invalid_category_ids = []

        # The draft preserves the original file while applying only choices
        # explicitly valid for each transaction direction.
        rows = transaction_import.rows.map do |row|
          next row unless row["status"] == "valid"

          default_category = default_categories.fetch(RowDirection.income?(row))
          category_id = selections[row["line_number"].to_s].presence || default_category.id.to_s
          selected = selected_lines.include?(row["line_number"].to_s)
          description = descriptions[row["line_number"].to_s].to_s.strip.presence || row["description"]
          category = categories_by_id[category_id]
          if category_id.present? && category && category.is_income == RowDirection.income?(row)
            row.merge(
              "category_id" => category_id.to_i,
              "category_name" => category.name,
              "description" => description,
              "selected" => selected
            )
          else
            invalid_category_ids << category_id if category_id.present?
            row.merge("category_id" => nil, "category_name" => nil, "selected" => selected)
          end
        end

        [rows, invalid_category_ids.compact.uniq]
      end

      def self.serialize_row(row, default_categories)
        default_category = default_categories.fetch(RowDirection.income?(row))

        {
          "line_number" => row.line_number,
          "date" => row.date&.iso8601,
          "amount" => row.amount&.to_s("F"),
          "description" => row.description,
          "category_name" => row.status == :valid ? default_category.name : row.category_name,
          "category_id" => row.status == :valid ? default_category.id : nil,
          "to_whom" => row.to_whom,
          "document_number" => row.document_number,
          "source_identifier" => row.source_identifier,
          "transaction_type" => row.transaction_type,
          "payment_method" => row.payment_method,
          "status" => row.status.to_s,
          "errors" => row.errors,
          "ignored_reason" => row.ignored_reason
        }
      end
      private_class_method :serialize_row


      def self.summary_for(rows)
        rows.group_by { |row| row["status"] }.transform_values(&:size).merge(
          "possible_duplicate" => rows.count { |row| row["possible_duplicate"] },
          "confirmed_duplicate" => rows.count { |row| row["confirmed_duplicate"] }
        )
      end
      private_class_method :summary_for
    end
  end
end
