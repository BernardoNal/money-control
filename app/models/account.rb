class Account < ApplicationRecord
  before_validation :sync_legacy_bank_name

  belongs_to :user
  belongs_to :bank_institution, optional: true
  has_many :transactions, dependent: :destroy
  has_many :transaction_imports, dependent: :destroy

  validates :name,:bank,:initial_balance, presence: true

  # Validação de valores numéricos
  validates :limit, :initial_balance, numericality: {  greater_than_or_equal_to: 0 }, allow_nil: true

  # Validação de comprimento
  validates :last_digits, length: { minimum: 4,maximum: 4 }, allow_nil: true

  def total_balance
    value = initial_balance.to_f + transactions.sum(:amount)
     ActionController::Base.helpers.number_with_precision(value, precision: 2, separator: ",", delimiter: ".")
  end

  def bank_display_name
    bank_institution&.short_name.presence || bank_institution&.name.presence || bank.presence || "-"
  end

  private

  # Keep the legacy text synchronized while existing records are migrated.
  def sync_legacy_bank_name
    return unless bank_institution

    self.bank = bank_institution.short_name.presence || bank_institution.name
  end

end
