module Investments
  class Asset < ApplicationRecord
    # Assets are modeled as a global market catalog, not as user-owned records.
    self.table_name = "investments_assets"

    enum :category, {
      stock: 0,
      fii: 1,
      etf: 2,
      crypto: 3,
      fixed_income: 4,
      international: 5
    }

    validates :name, :symbol, :category, :currency, presence: true
    validates :symbol, uniqueness: true
  end
end
