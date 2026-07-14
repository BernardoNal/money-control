module Investments
  class PortfolioDashboardBuilder
    AssetEntry = Struct.new(
      :asset,
      :quantity,
      :average_price,
      :invested_amount,
      :market_price,
      :current_value,
      :price_as_of,
      :price_source,
      :allocation_percentage,
      keyword_init: true
    )

    HistoricalPointEntry = Struct.new(
      :date,
      :invested_amount,
      keyword_init: true
    )

    CategoryAllocationEntry = Struct.new(
      :category,
      :label,
      :invested_amount,
      :allocation_percentage,
      keyword_init: true
    )

    SubcategoryAllocationEntry = Struct.new(
      :subcategory,
      :label,
      :invested_amount,
      :allocation_percentage,
      keyword_init: true
    )

    Result = Struct.new(
      :portfolio,
      :total_invested_amount,
      :current_portfolio_value,
      :unrealized_profit_loss,
      :passive_income_summary,
      :last_transaction_date,
      :recent_transactions,
      :historical_evolution_points,
      :asset_entries,
      :category_allocations,
      :subcategory_allocations,
      :priced_assets_count,
      :unpriced_asset_symbols,
      :market_value_approximation,
      keyword_init: true
    )

    ZERO = BigDecimal("0")

    def initialize(portfolio:, price_lookup_service: MarketData::PriceLookupService.new)
      @portfolio = portfolio
      @price_lookup_service = price_lookup_service
    end

    def self.call(portfolio:, price_lookup_service: MarketData::PriceLookupService.new)
      new(portfolio: portfolio, price_lookup_service: price_lookup_service).call
    end

    def call
      grouped_transactions = transactions.group_by(&:asset)
      base_entries = grouped_transactions.filter_map do |asset, asset_transactions|
        build_asset_entry(asset, asset_transactions)
      end

      historical_evolution_points = build_historical_evolution_points(transactions)
      priced_entries = attach_market_prices(base_entries)
      total_invested_amount = base_entries.sum { |entry| entry.invested_amount }
      asset_entries = attach_allocation(priced_entries, total_invested_amount)
      category_allocations = build_category_allocations(asset_entries, total_invested_amount)
      subcategory_allocations = build_subcategory_allocations(asset_entries, total_invested_amount)
      current_portfolio_value = asset_entries.sum { |entry| entry.current_value }
      unpriced_asset_symbols = asset_entries
        .select { |entry| entry.price_source == :cost_basis }
        .map { |entry| entry.asset.symbol }

      sorted_transactions = transactions.sort_by(&:date)

      Result.new(
        portfolio: portfolio,
        total_invested_amount: total_invested_amount,
        current_portfolio_value: current_portfolio_value,
        unrealized_profit_loss: current_portfolio_value - total_invested_amount,
        passive_income_summary: incomes.sum(&:net_amount),
        last_transaction_date: sorted_transactions.last&.date,
        recent_transactions: sorted_transactions.last(3).reverse,
        historical_evolution_points: historical_evolution_points,
        asset_entries: asset_entries.sort_by { |entry| [-entry.invested_amount, entry.asset.symbol] },
        category_allocations: category_allocations,
        subcategory_allocations: subcategory_allocations,
        priced_assets_count: asset_entries.count { |entry| entry.price_source == :market },
        unpriced_asset_symbols: unpriced_asset_symbols,
        market_value_approximation: unpriced_asset_symbols.any?
      )
    end

    private

    attr_reader :portfolio, :price_lookup_service

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
        market_price: nil,
        current_value: total_cost,
        price_as_of: nil,
        price_source: :cost_basis,
        allocation_percentage: ZERO
      )
    end

    def attach_market_prices(entries)
      entries.map do |entry|
        price_data = fetch_price_for(entry.asset.symbol)

        if price_data.present?
          entry.market_price = price_data.price
          entry.current_value = price_data.price * entry.quantity
          entry.price_as_of = price_data.as_of
          entry.price_source = :market
        else
          entry.current_value = entry.invested_amount
          entry.price_source = :cost_basis
        end

        entry
      end
    end

    def build_historical_evolution_points(sorted_transactions)
      running_positions = Hash.new { |hash, key| hash[key] = { quantity: ZERO, total_cost: ZERO } }

      sorted_transactions
        .group_by(&:date)
        .map do |date, dated_transactions|
          dated_transactions.each do |transaction|
            position = running_positions[transaction.asset_id]

            case transaction.transaction_type
            when "buy"
              position[:quantity] += transaction.quantity
              position[:total_cost] += (transaction.quantity * transaction.price) + transaction.fees
            when "sell"
              raise ArgumentError, "sell quantity exceeds current position" if transaction.quantity > position[:quantity]

              average_price = average_price_for(position[:quantity], position[:total_cost])
              position[:quantity] -= transaction.quantity
              position[:total_cost] -= average_price * transaction.quantity
              position[:total_cost] = ZERO if position[:quantity].zero?
            end
          end

          HistoricalPointEntry.new(
            date: date,
            invested_amount: running_positions.values.sum { |position| position[:total_cost] }
          )
        end
    end

    def attach_allocation(entries, total_invested_amount)
      entries.map do |entry|
        entry.allocation_percentage = allocation_percentage_for(entry.invested_amount, total_invested_amount)

        entry
      end
    end

    def build_category_allocations(entries, total_invested_amount)
      entries
        .group_by { |entry| entry.asset.category }
        .map do |category, category_entries|
          invested_amount = category_entries.sum(&:invested_amount)

          CategoryAllocationEntry.new(
            category: category,
            label: human_category(category),
            invested_amount: invested_amount,
            allocation_percentage: allocation_percentage_for(invested_amount, total_invested_amount)
          )
        end
        .sort_by { |entry| [-entry.invested_amount, entry.label] }
    end

    def build_subcategory_allocations(entries, total_invested_amount)
      entries
        .group_by { |entry| entry.asset.subcategory.presence }
        .map do |subcategory, subcategory_entries|
          invested_amount = subcategory_entries.sum(&:invested_amount)

          SubcategoryAllocationEntry.new(
            subcategory: subcategory,
            label: human_subcategory(subcategory),
            invested_amount: invested_amount,
            allocation_percentage: allocation_percentage_for(invested_amount, total_invested_amount)
          )
        end
        .sort_by { |entry| [-entry.invested_amount, entry.label] }
    end

    def allocation_percentage_for(amount, total_amount)
      return ZERO if total_amount.zero?

      (amount / total_amount) * 100
    end

    def human_category(category)
      I18n.t("activerecord.attributes.investments/asset.categories.#{category}")
    end

    def human_subcategory(subcategory)
      return "Sem subcategoria" if subcategory.blank?

      I18n.t("activerecord.attributes.investments/asset.subcategories.#{subcategory}")
    end

    def average_price_for(quantity, total_cost)
      return ZERO if quantity.zero?

      total_cost / quantity
    end

    def fetch_price_for(symbol)
      price_lookup_service.call(symbol: symbol)
    rescue MarketData::ConfigurationError, MarketData::NotFoundError, MarketData::ProviderError
      nil
    end
  end
end
