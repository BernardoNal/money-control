module Investments
  class PortfolioDashboardBuilder
    AssetEntry = Struct.new(
      :asset,
      :quantity,
      :average_price,
      :invested_amount,
      :current_value,
      :allocation_percentage,
      keyword_init: true
    )

    Result = Struct.new(
      :portfolio,
      :total_invested_amount,
      :current_portfolio_value,
      :unrealized_profit_loss,
      :passive_income_summary,
      :asset_entries,
      keyword_init: true
    )

    ZERO = BigDecimal("0")

    def initialize(portfolio:)
      @portfolio = portfolio
    end

    def self.call(portfolio:)
      new(portfolio: portfolio).call
    end

    def call
      grouped_transactions = transactions.group_by(&:asset)
      base_entries = grouped_transactions.filter_map do |asset, asset_transactions|
        build_asset_entry(asset, asset_transactions)
      end

      total_invested_amount = base_entries.sum { |entry| entry.invested_amount }
      asset_entries = attach_allocation(base_entries, total_invested_amount)

      Result.new(
        portfolio: portfolio,
        total_invested_amount: total_invested_amount,
        current_portfolio_value: total_invested_amount,
        unrealized_profit_loss: ZERO,
        passive_income_summary: incomes.sum(&:net_amount),
        asset_entries: asset_entries.sort_by { |entry| [-entry.invested_amount, entry.asset.symbol] }
      )
    end

    private

    attr_reader :portfolio

    def transactions
      portfolio
        .transactions
        .includes(:asset)
        .where(transaction_type: [:buy, :sell])
        .order(:date, :id)
    end

    def incomes
      @incomes ||= portfolio.incomes.to_a
    end

    def build_asset_entry(asset, asset_transactions)
      quantity = ZERO
      total_cost = ZERO

      asset_transactions.each do |transaction|
        case transaction.transaction_type
        when "buy"
          quantity += transaction.quantity
          total_cost += (transaction.quantity * transaction.price) + transaction.fees
        when "sell"
          raise ArgumentError, "sell quantity exceeds current position" if transaction.quantity > quantity

          average_price = average_price_for(quantity, total_cost)
          quantity -= transaction.quantity
          total_cost -= average_price * transaction.quantity
          total_cost = ZERO if quantity.zero?
        end
      end

      return if quantity.zero?

      AssetEntry.new(
        asset: asset,
        quantity: quantity,
        average_price: average_price_for(quantity, total_cost),
        invested_amount: total_cost,
        current_value: total_cost,
        allocation_percentage: ZERO
      )
    end

    def attach_allocation(entries, total_invested_amount)
      entries.map do |entry|
        entry.allocation_percentage =
          if total_invested_amount.zero?
            ZERO
          else
            (entry.invested_amount / total_invested_amount) * 100
          end

        entry
      end
    end

    def average_price_for(quantity, total_cost)
      return ZERO if quantity.zero?

      total_cost / quantity
    end
  end
end
