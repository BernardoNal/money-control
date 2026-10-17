module Transactions
  module Imports
    class Confirmer
      Result = Struct.new(:success?, :message, :created_count, keyword_init: true)

      def self.call(transaction_import:, user:)
        new(transaction_import: transaction_import, user: user).call
      end

      def initialize(transaction_import:, user:)
        @transaction_import = transaction_import
        @user = user
      end

      def call
        return failure("Esta importação já foi confirmada.") unless transaction_import.pending?
        return expire_import if expired?

        account = user.accounts.find_by(id: transaction_import.account_id)
        return failure("A conta desta importação não está disponível.") unless account

        rows = transaction_import.rows.select do |row|
          row["status"] == "valid" && row.fetch("selected", true) != false
        end
        return failure("Não há lançamentos válidos para importar.") if rows.empty?

        rows = rows.map do |row|
          next row if row["category_id"].present?

          # A categoria padrão é escolhida pela direção do lançamento para que
          # entradas e saídas nunca recebam uma categoria incompatível.
          default_category = Category.uncategorized(income: RowDirection.income?(row))
          row.merge("category_id" => default_category.id)
        end
        categories = categories_for(rows)
        category_ids = rows.map { |row| row["category_id"].to_i }.uniq
        return failure("Uma ou mais categorias não pertencem ao usuário atual.") if categories.size != category_ids.size
        return failure("Uma ou mais categorias não correspondem ao tipo do lançamento.") unless categories_match_rows?(rows, categories)

        created_count = 0
        # A criação das transações e a conclusão do rascunho precisam ser uma
        # única operação: uma falha não pode deixar uma importação pela metade.
        ActiveRecord::Base.transaction do
          rows.each do |row|
            Transaction.create!(
              account: account,
              category: categories.fetch(row["category_id"].to_i),
              transaction_import: transaction_import,
              source_document_number: row["document_number"],
              import_fingerprint: row["import_fingerprint"],
              amount: row["amount"],
              date: row["date"],
              description: row["description"],
              to_whom: row["to_whom"],
              payment_method: row["payment_method"]
            )
            created_count += 1
          end

          transaction_import.update!(status: "completed", completed_at: Time.current)
        end

        success("Importação concluída com #{created_count} lançamento(s).", created_count)
      rescue ActiveRecord::RecordInvalid => e
        failure("A importação não foi concluída: #{e.record.errors.full_messages.to_sentence}")
      end

      private

      attr_reader :transaction_import, :user

      def categories_for(rows)
        ids = rows.filter_map { |row| row["category_id"].presence }.map(&:to_i).uniq
        Category.for_user(user.id).where(id: ids).index_by(&:id)
      end

      def categories_match_rows?(rows, categories)
        rows.all? do |row|
          category = categories[row["category_id"].to_i]
          category && category.is_income == RowDirection.income?(row)
        end
      end

      def expired?
        transaction_import.expires_at.present? && transaction_import.expires_at <= Time.current
      end

      def expire_import
        transaction_import.update!(status: "expired")
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
