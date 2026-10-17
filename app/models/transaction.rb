class Transaction < ApplicationRecord
  belongs_to :category
  belongs_to :account
  belongs_to :transaction_import, optional: true

  validates :amount, :date, :description, presence: true
end
