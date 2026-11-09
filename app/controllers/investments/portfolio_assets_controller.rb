module Investments
  class PortfolioAssetsController < ApplicationController
    PERFORMANCE_PERIODS = {
      "7d" => "Semana",
      "30d" => "Mês",
      "90d" => "90 dias"
    }.freeze

    before_action :set_portfolio
    before_action :set_asset

    def show
      @detail = Investments::PortfolioAssetDetailBuilder.call(
        portfolio: @portfolio,
        asset: @asset
      )
      @performance = Investments::PortfolioAssetPerformanceBuilder.call(
        portfolio: @portfolio,
        asset: @asset,
        current_market_value: @detail.current_market_value
      )
      @performance_history = Investments::PortfolioAssetPerformanceHistoryBuilder.call(
        portfolio: @portfolio,
        asset: @asset,
        to_date: @detail.price_as_of&.to_date,
        period: performance_period
      )
      asset_transactions = @portfolio.transactions
        .where(asset: @asset)
        .order(:date, :id)
      @asset_transactions_page_size = 5
      @asset_transactions_total = asset_transactions.count
      requested_offset = params[:history_set].to_i
      @asset_transactions_offset = requested_offset % @asset_transactions_page_size == 0 ? requested_offset : 0
      @asset_transactions = asset_transactions
        .limit(@asset_transactions_page_size)
        .offset(@asset_transactions_offset)

      @asset_incomes = @portfolio.incomes
        .where(asset: @asset)
        .order(:payment_date, :id)
      @asset_incomes_by_type = @asset_incomes.group_by(&:income_type)
        .sort_by { |income_type, _| Investments::Income.income_types.fetch(income_type) }
        .to_h
      @selected_income_type = permitted_income_type(params[:income_type_tab])
      @selected_income_type = @asset_incomes_by_type.keys.first unless @asset_incomes_by_type.key?(@selected_income_type)
      selected_incomes = @asset_incomes_by_type.fetch(@selected_income_type, [])
      @asset_income_page_size = 5
      @asset_income_total = selected_incomes.size
      requested_income_offset = params[:income_history_set].to_i
      @asset_income_offset = requested_income_offset % @asset_income_page_size == 0 ? requested_income_offset : 0
      @visible_asset_incomes = selected_incomes.slice(@asset_income_offset, @asset_income_page_size) || []
    end

    private

    def set_portfolio
      @portfolio = current_user.investment_portfolios.find(params[:portfolio_id])
    end

    def set_asset
      # Asset access is derived from portfolio transactions because assets are
      # global catalog records rather than user-owned records.
      @asset = @portfolio.transactions.includes(:asset).find_by(asset_id: params[:asset_id])&.asset
      return if @asset

      redirect_to investments_portfolio_path(@portfolio), alert: "Ativo não encontrado neste portfólio."
    end

    def permitted_income_type(value)
      return if value.blank?
      return value if Investments::Income.income_types.key?(value)

      nil
    end

    def performance_period
      value = params[:performance_period].to_s
      PERFORMANCE_PERIODS.key?(value) ? value : "90d"
    end

    helper_method :performance_period
  end
end
