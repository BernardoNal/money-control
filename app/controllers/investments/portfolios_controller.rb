module Investments
  class PortfoliosController < ApplicationController
    before_action :set_portfolio, only: %i[show edit update destroy]

    def index
      @portfolios = current_user.investment_portfolios.order(:name)
    end

    def show
      @dashboard = Investments::PortfolioDashboardBuilder.call(portfolio: @portfolio)
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
  end
end
