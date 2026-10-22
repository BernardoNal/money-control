module Investments
  class IncomeImport < ApplicationRecord
    self.table_name = "investments_income_imports"

    belongs_to :portfolio, class_name: "Investments::Portfolio"

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
end
