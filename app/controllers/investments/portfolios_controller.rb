module Investments
  class PortfoliosController < ApplicationController
    DashboardFilters = Struct.new(
      :period,
      :from_date,
      :to_date,
      :category,
      keyword_init: true
    )

    before_action :set_portfolio, only: %i[show edit update destroy]

    def index
      @portfolios = current_user.investment_portfolios.order(:name)
      @portfolio_summaries = @portfolios.each_with_object({}) do |portfolio, summaries|
        summaries[portfolio.id] = Investments::PortfolioDashboardBuilder.call(portfolio: portfolio)
      end
    end

    def show
      @dashboard_filters = build_dashboard_filters
      @category_options = dashboard_category_options
      @dashboard = Investments::PortfolioDashboardBuilder.call(
        portfolio: @portfolio,
        from_date: @dashboard_filters.from_date,
        to_date: @dashboard_filters.to_date,
        category: @dashboard_filters.category
      )
    end

    def new
      @portfolio = current_user.investment_portfolios.new
      render :form
    end

    def create
      @portfolio = current_user.investment_portfolios.new(portfolio_params)

      if @portfolio.save
        redirect_to investments_portfolio_path(@portfolio), notice: "Portfolio criado com sucesso."
      else
        render :form, status: :unprocessable_entity
      end
    end

    def edit
      render :form
    end

    def update
      if @portfolio.update(portfolio_params)
        redirect_to investments_portfolio_path(@portfolio), notice: "Portfolio alterado com sucesso."
      else
        render :form, status: :unprocessable_entity
      end
    end

    def destroy
      @portfolio.destroy

      redirect_to investments_portfolios_path, notice: "Portfolio excluido com sucesso."
    end

    private

    def portfolio_params
      params.require(:investments_portfolio).permit(:name)
    end

    def set_portfolio
      # User-owned portfolios must always be resolved through the authenticated user.
      @portfolio = current_user.investment_portfolios.find(params[:id])
    end

    def build_dashboard_filters
      period = permitted_period(params[:period])
      range = default_period_range(period)
      manual_from_date = parse_filter_date(params[:from_date])
      manual_to_date = parse_filter_date(params[:to_date])
      use_manual_dates = params[:period].blank? && (manual_from_date.present? || manual_to_date.present?)

      DashboardFilters.new(
        period: period,
        from_date: use_manual_dates ? manual_from_date : range[:from_date],
        to_date: use_manual_dates ? manual_to_date : range[:to_date],
        category: permitted_category(params[:category])
      )
    end

    def parse_filter_date(value)
      return if value.blank?

      Date.iso8601(value)
    rescue ArgumentError
      nil
    end

    def permitted_category(value)
      return if value.blank?
      return value if Investments::Asset.categories.key?(value)

      nil
    end

    def permitted_period(value)
      return "all" if value.blank?

      %w[all 30d 3m 6m 1y].include?(value) ? value : "all"
    end

    def default_period_range(period)
      return { from_date: nil, to_date: nil } if period == "all"

      to_date = Date.current
      from_date =
        case period
        when "3m"
          to_date - 3.months
        when "6m"
          to_date - 6.months
        when "1y"
          to_date - 1.year
        else
          to_date - 30.days
        end

      { from_date: from_date, to_date: to_date }
    end

    def dashboard_category_options
      Investments::Asset.categories.keys.map do |key|
        [
          I18n.t("activerecord.attributes.investments/asset.categories.#{key}"),
          key
        ]
      end
    end
  end
end
