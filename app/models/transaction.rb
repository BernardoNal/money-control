class Transaction < ApplicationRecord
  belongs_to :category
  belongs_to :account

  validates :amount, :date, :description, presence: true
end
