class Account < ApplicationRecord
  belongs_to :user
  has_many :transactions, dependent: :destroy

  validates :name,:bank,:initial_balance, presence: true

  # Validação de valores numéricos
  validates :limit, :initial_balance, numericality: {  greater_than_or_equal_to: 0 }, allow_nil: true

  # Validação de comprimento
  validates :last_digits, length: { minimum: 4,maximum: 4 }, allow_nil: true
end
