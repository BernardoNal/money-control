module Investments
  class Portfolio < ApplicationRecord
    # The namespace keeps investment features grouped as this domain grows.
    self.table_name = "investments_portfolios"

    belongs_to :user

    validates :name, presence: true, uniqueness: { scope: :user_id }
  end
end
