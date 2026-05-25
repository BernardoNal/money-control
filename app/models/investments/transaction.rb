module Investments
  class Transaction < ApplicationRecord
    self.table_name = "investments_transactions"

    belongs_to :portfolio, class_name: "Investments::Portfolio"
    belongs_to :asset, class_name: "Investments::Asset"

    enum :transaction_type, {
      buy: 0,
      sell: 1,
      transfer: 2,
      split: 3,
      reverse_split: 4
    }, prefix: true

    validates :transaction_type, :quantity, :date, presence: true
    validates :quantity, numericality: { greater_than: 0 }
    validates :fees, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
    validates :price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
    validate :price_required_for_market_trade

    private

    def price_required_for_market_trade
      return unless transaction_type_buy? || transaction_type_sell?
      return if price.present?

      errors.add(:price, "can't be blank")
    end
  end
end
