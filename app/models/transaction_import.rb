class TransactionImport < ApplicationRecord
  belongs_to :account

  STATUSES = %w[pending completed expired].freeze

  validates :original_filename, :status, presence: true
  validates :status, inclusion: { in: STATUSES }

  scope :pending, -> { where(status: "pending") }

  def pending?
    status == "pending"
  end
end
