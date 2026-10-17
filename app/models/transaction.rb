class Transaction < ApplicationRecord
  PAYMENT_METHODS = [
    "Pix",
    "Cartão de crédito",
    "Cartão de débito",
    "Boleto",
    "TED",
    "DOC",
    "Transferência",
    "Dinheiro",
    "Outro"
  ].freeze

  belongs_to :category
  belongs_to :account
  belongs_to :transaction_import, optional: true

  validates :amount, :date, :description, presence: true
end
