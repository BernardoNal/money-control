module Investments
  class TransactionsController < ApplicationController
    before_action :set_transaction, only: %i[
      show
      edit
      update
      destroy
    ]

    def index
      @total_transactions = 5
      @offset = params[:set].to_i % @total_transactions == 0 ? params[:set].to_i : 0

      @selected_transaction_type = permitted_transaction_type(params[:transaction_type])
      @selected_asset = permitted_asset(params[:asset])
      @selected_portfolio = permitted_portifolio(params[:portfolio])

     @transactions = policy_scope(Investments::Transaction)
      .includes(:asset, :portfolio)

      load_filter_collections

      @transactions = @transactions.where(transaction_type: @selected_transaction_type) if @selected_transaction_type.present?
      @transactions = @transactions.where(asset: @selected_asset) if @selected_asset.present?
      @transactions = @transactions.where(portfolio: @selected_portfolio) if @selected_portfolio.present?

      @visible_transactions = @transactions
        .order(date: :desc)
        .limit(@total_transactions)
        .offset(@offset)
    end

    def show
    end

    def new
      @transaction = Investments::Transaction.new

      load_form_collections

      render :form
    end

    def create
      @transaction = Investments::Transaction.new(transaction_params)

        set_transaction_portfolio
        return if performed?

      load_form_collections

      if @transaction.save
        redirect_to investments_transaction_path(@transaction),
                    notice: t(".created")
      else
        render :form, status: :unprocessable_entity
      end
    end

    def edit
      load_form_collections

      render :form
    end

    def update
      load_form_collections

      if @transaction.update(transaction_params)
        redirect_to investments_transaction_path(@transaction),
                    notice: t(".updated")
      else
        render :form, status: :unprocessable_entity
      end
    end

    def destroy
      @transaction.destroy

      redirect_to investments_transactions_path,
                  notice: t(".destroyed")
    end

    private

    def transaction_params
      params.require(:investments_transaction).permit(
        :portfolio_id,
        :asset_id,
        :transaction_type,
        :quantity,
        :price,
        :fees,
        :date,
        :notes
      )
    end

    def set_transaction
      @transaction = Investments::Transaction.find(params[:id])
      authorize @transaction
    end

    def permitted_transaction_type(value)
      return if value.blank?
      return value if Investments::Transaction.transaction_types.key?(value)

      nil
    end

    def permitted_asset(value)
      return if value.blank?
      return value if Investments::Asset.where(active: true).exists?(id: value)

      nil
    end

    def permitted_portifolio(value)
      return if value.blank?
      return value if Investments::Portfolio.where(user: current_user).exists?(id: value)
      nil
    end

    def load_form_collections
      @portfolios = current_user
        .investment_portfolios
        .order(:name)

      @assets = Investments::Asset
        .where(active: true)
        .order(:symbol)

      @transaction_types =
        Investments::Transaction.transaction_types.keys.map do |key|
          [
            I18n.t(
              "activerecord.attributes.investments/transaction.transaction_types.#{key}"
            ),
            key
          ]
        end
    end

    def load_filter_collections
      @filter_assets = @transactions
        .joins(:asset)
        .distinct
        .pluck("investments_assets.symbol", "investments_assets.id")
        .sort_by(&:first)

      @filter_portfolios = @transactions
        .joins(:portfolio)
        .distinct
        .pluck("investments_portfolios.name", "investments_portfolios.id")
        .sort_by(&:first)

       @transaction_types =
        Investments::Transaction.transaction_types.keys.map do |key|
          [
            I18n.t(
              "activerecord.attributes.investments/transaction.transaction_types.#{key}"
            ),
            key
          ]
        end
    end

    def set_transaction_portfolio
      @transaction.portfolio = current_user.investment_portfolios.find(
        transaction_params[:portfolio_id]
      )
    rescue ActiveRecord::RecordNotFound
      redirect_to root_path
    end
  end
end
