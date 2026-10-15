module Investments
  class IncomeTaxReportBuilder
    Report = Struct.new(:year, :asset_groups, :totals, keyword_init: true)
    AssetGroup = Struct.new(:asset, :income_type_groups, :totals, keyword_init: true)
    IncomeTypeGroup = Struct.new(:income_type, :label, :incomes, :totals, keyword_init: true)

    def self.call(incomes:, year:)
      new(incomes: incomes, year: year).call
    end

    def initialize(incomes:, year:)
      @incomes = incomes
      @year = normalize_year(year)
    end

    def call
      report_incomes = scoped_incomes
      asset_groups = build_asset_groups(report_incomes)

      Report.new(
        year: year,
        asset_groups: asset_groups,
        totals: totals_for(report_incomes)
      )
    end

    private

    attr_reader :incomes, :year

    # Keep the report contract limited to one selectable calendar year.
    def normalize_year(value)
      normalized = Integer(value, exception: false)
      return normalized if normalized&.between?(1, 9_999)

      raise ArgumentError, "year must be a valid calendar year"
    end

    # The caller owns the authorization boundary; this service only narrows it to the requested year.
    # Eager loading and stable ordering keep HTML and PDF renderers consistent without N+1 queries.
    def scoped_incomes
      incomes
        .where(payment_date: Date.new(year, 1, 1)..Date.new(year, 12, 31))
        .includes(:asset)
        .order(payment_date: :asc, id: :asc)
        .to_a
    end

    # Assets are the primary report dimension and income types are the secondary dimension.
    # Sorting assets by symbol and types by enum key makes both output formats deterministic.
    def build_asset_groups(report_incomes)
      report_incomes.group_by(&:asset).sort_by { |asset, _| [asset.symbol.to_s, asset.id] }.map do |asset, asset_incomes|
        type_groups = asset_incomes.group_by(&:income_type).sort_by(&:first).map do |income_type, type_incomes|
          IncomeTypeGroup.new(
            income_type: income_type,
            label: type_incomes.first.human_income_type,
            incomes: type_incomes,
            totals: totals_for(type_incomes)
          )
        end

        AssetGroup.new(
          asset: asset,
          income_type_groups: type_groups,
          totals: totals_for(asset_incomes)
        )
      end
    end

    # Totals are derived only from persisted monetary fields; no tax classification or value is inferred.
    def totals_for(records)
      {
        gross_amount: records.sum { |income| income.gross_amount.to_d },
        tax_amount: records.sum { |income| income.tax_amount.to_d },
        net_amount: records.sum { |income| income.net_amount.to_d }
      }
    end
  end
end
