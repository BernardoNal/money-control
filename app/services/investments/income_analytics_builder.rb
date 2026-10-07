module Investments
  class IncomeAnalyticsBuilder
    Result = Struct.new(
      :total_net_amount,
      :income_totals_by_type,
      :income_count,
      keyword_init: true
    )

    def self.call(incomes:)
      new(incomes: incomes).call
    end

    def initialize(incomes:)
      @incomes = incomes
    end

    def call
      grouped_totals = incomes.group(:income_type).sum(:net_amount)

      Result.new(
        total_net_amount: incomes.sum(:net_amount).to_d,
        income_totals_by_type: grouped_totals.transform_keys { |value| income_type_key(value) }
          .transform_values(&:to_d),
        income_count: incomes.count
      )
    end

    private

    attr_reader :incomes

    def income_type_key(value)
      return value.to_s if Investments::Income.income_types.key?(value.to_s)

      Investments::Income.income_types.key(value.to_i)
    end
  end
end
