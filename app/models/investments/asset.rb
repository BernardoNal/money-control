module Investments
  class Asset < ApplicationRecord
    # Assets are modeled as a global market catalog, not as user-owned records.
    self.table_name = "investments_assets"

    has_many :incomes, class_name: "Investments::Income", dependent: :restrict_with_exception
    has_many :transactions, class_name: "Investments::Transaction", dependent: :restrict_with_exception

    enum :category, {
      stock: 0,
      fii: 1,
      etf: 2,
      crypto: 3,
      fixed_income: 4,
      international: 5
    }

    enum :subcategory, {
      paper: 0,
      brick: 1,
      banks: 2,
      energy: 3,
      technology: 4
    }

    validates :name, :symbol, :category, :currency, presence: true
    validates :symbol, uniqueness: true
  end
end
