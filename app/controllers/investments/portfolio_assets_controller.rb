module Investments
  class PortfolioAssetsController < ApplicationController
    before_action :set_portfolio
    before_action :set_asset

    def show
      @detail = Investments::PortfolioAssetDetailBuilder.call(
        portfolio: @portfolio,
        asset: @asset
      )
      @asset_transactions = @portfolio.transactions
        .where(asset: @asset)
        .order(:date, :id)
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
  end
end
