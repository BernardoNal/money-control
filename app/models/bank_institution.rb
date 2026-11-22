class BankInstitution < ApplicationRecord
  has_many :accounts, inverse_of: :bank_institution

  validates :bank_code, :name, :source, presence: true
  validates :bank_code, uniqueness: { scope: :source }

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:bank_code) }
end
