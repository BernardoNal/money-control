class Account < ApplicationRecord
  belongs_to :user
  belongs_to :bank_institution
  has_many :transactions, dependent: :destroy
  has_many :transaction_imports, dependent: :destroy

  validates :name, :initial_balance, presence: true

  # Validação de valores numéricos
  validates :limit, :initial_balance, numericality: {  greater_than_or_equal_to: 0 }, allow_nil: true

  # Validação de comprimento
  validates :last_digits, length: { minimum: 4,maximum: 4 }, allow_nil: true

  def total_balance
    value = initial_balance.to_f + transactions.sum(:amount)
     ActionController::Base.helpers.number_with_precision(value, precision: 2, separator: ",", delimiter: ".")
  end

  def bank_display_name
    bank_institution.short_name.presence || bank_institution.name
  end
end
