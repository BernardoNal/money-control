class BankInstitution < ApplicationRecord
  validates :bank_code, :name, :source, presence: true
  validates :bank_code, uniqueness: { scope: :source }

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:bank_code) }
end
