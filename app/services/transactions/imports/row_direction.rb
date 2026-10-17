module Transactions
  module Imports
    module RowDirection
      def self.income?(row)
        type = row["transaction_type"].to_s
        return true if type.casecmp("Entrada").zero?
        return false if type.casecmp("Saída").zero?

        row["amount"].to_f >= 0
      end
    end
  end
end
