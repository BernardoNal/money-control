module Investments
  class IncomeAnalyticsBuilder
    Result = Struct.new(
      :total_net_amount,
      :income_totals_by_type,
      :income_count,
      :average_net_amount,
      :largest_net_amount,
      :largest_income,
      :last_30_days_total,
      :latest_incomes,
      keyword_init: true
    )

    def self.call(incomes:, from_date: nil, to_date: Date.current)
      new(incomes: incomes, from_date: from_date, to_date: to_date).call
    end

    def initialize(incomes:, from_date: nil, to_date: Date.current)
      @incomes = incomes
      @from_date = from_date
      @to_date = to_date
    end

    def call
      scoped_incomes = period_scope
      grouped_totals = scoped_incomes.group(:income_type).sum(:net_amount)
      largest_income = scoped_incomes.includes(:asset).order(net_amount: :desc, payment_date: :desc, id: :desc).first

      Result.new(
        total_net_amount: scoped_incomes.sum(:net_amount).to_d,
        income_totals_by_type: grouped_totals.transform_keys { |value| income_type_key(value) }
          .transform_values(&:to_d),
        income_count: scoped_incomes.count,
        average_net_amount: average_net_amount(scoped_incomes),
        largest_net_amount: largest_income&.net_amount.to_d,
        largest_income: largest_income,
        last_30_days_total: incomes.where(payment_date: 29.days.ago.to_date..Date.current).sum(:net_amount).to_d,
        latest_incomes: scoped_incomes.includes(:asset, :portfolio).order(payment_date: :desc, id: :desc).limit(3).to_a
      )
    end

    private

    attr_reader :incomes, :from_date, :to_date

    def period_scope
      return incomes.where(payment_date: from_date..to_date) if from_date.present?

      incomes.where(payment_date: ..to_date)
    end

    def average_net_amount(scope)
      count = scope.count
      return BigDecimal("0") if count.zero?

      (scope.sum(:net_amount).to_d / count).round(2)
    end

    def income_type_key(value)
      return value.to_s if Investments::Income.income_types.key?(value.to_s)

      Investments::Income.income_types.key(value.to_i)
    end
  end
end
