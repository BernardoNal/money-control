module Investments
  class Portfolio < ApplicationRecord
    # The namespace keeps investment features grouped as this domain grows.
    self.table_name = "investments_portfolios"

    belongs_to :user
    has_many :incomes, class_name: "Investments::Income", dependent: :destroy
    has_many :transactions, class_name: "Investments::Transaction", dependent: :destroy

    validates :name, presence: true, uniqueness: { scope: :user_id }
  end
end
