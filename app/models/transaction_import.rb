class TransactionImport < ApplicationRecord
  belongs_to :account
  has_many :transactions, dependent: :nullify

  STATUSES = %w[pending completed expired cancelled].freeze

  validates :original_filename, :status, presence: true
  validates :status, inclusion: { in: STATUSES }

  scope :pending, -> { where(status: "pending") }

  def pending?
    status == "pending"
  end

  def cancelable?
    pending?
  end
end
