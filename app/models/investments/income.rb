module Investments
  class Income < ApplicationRecord
    self.table_name = "investments_incomes"

    belongs_to :portfolio, class_name: "Investments::Portfolio"
    belongs_to :asset, class_name: "Investments::Asset"

    enum :income_type, {
      dividends: 0,
      jcp: 1,
      stock_lending: 2,
      fii_income: 3,
      amortization: 4,
      staking: 5
    }, prefix: true

    validates :income_type, :gross_amount, :net_amount, :payment_date, presence: true
    validates :gross_amount, :net_amount, :tax_amount,
              numericality: { greater_than_or_equal_to: 0 }
    validate :net_amount_cannot_exceed_gross_amount

    private

    def net_amount_cannot_exceed_gross_amount
      return if gross_amount.blank? || net_amount.blank?
      return if net_amount <= gross_amount

      errors.add(:net_amount, "cannot be greater than gross amount")
    end
  end
end
