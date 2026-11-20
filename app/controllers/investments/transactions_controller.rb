module Investments
  class TransactionsController < ApplicationController
    before_action :set_transaction, only: %i[
      show
      edit
      update
      destroy
    ]

    def index
      load_index_view

      @transaction_modal = permitted_modal(params[:modal])
      @modal_transaction = transaction_for_modal(@transaction_modal) if @transaction_modal.present?
      load_form_collections if %w[new edit].include?(@transaction_modal)
    end

    def show
      redirect_to investments_transactions_path(modal: "show", transaction_id: @transaction.id)
    end

    def new
      redirect_to investments_transactions_path(modal: "new")
    end

    def create
      @transaction = Investments::Transaction.new(transaction_params)

      set_transaction_portfolio
      return if performed?

      if @transaction.save
        redirect_to investments_transactions_path(modal: "show", transaction_id: @transaction.id), notice: t(".created")
      else
        prepare_invalid_modal("new")
        render :index, status: :unprocessable_entity
      end
    end

    def edit
      redirect_to investments_transactions_path(modal: "edit", transaction_id: @transaction.id)
    end

    def update
      set_transaction_portfolio
      return if performed?

      if @transaction.update(transaction_params.except(:portfolio_id))
        redirect_to investments_transactions_path(modal: "show", transaction_id: @transaction.id), notice: t(".updated")
      else
        prepare_invalid_modal("edit")
        render :index, status: :unprocessable_entity
      end
    end

    def destroy
      @transaction.destroy

      redirect_to investments_transactions_path,
                  notice: t(".destroyed")
    end

    private

    def load_index_view
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

    def prepare_invalid_modal(modal)
      load_index_view
      @transaction_modal = modal
      @modal_transaction = @transaction
      load_form_collections
    end

    def permitted_modal(value)
      %w[new edit show].include?(value) ? value : nil
    end

    def transaction_for_modal(modal)
      return Investments::Transaction.new if modal == "new"

      policy_scope(Investments::Transaction).find(params[:transaction_id])
    rescue ActiveRecord::RecordNotFound
      redirect_to investments_transactions_path, alert: "Movimentação não encontrada ou indisponível."
      nil
    end

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
      portfolio_id = transaction_params[:portfolio_id]
      return if @transaction.persisted? && portfolio_id.blank?

      # Scope destination portfolios to the current user before changing ownership.
      @transaction.portfolio = current_user.investment_portfolios.find(portfolio_id)
    rescue ActiveRecord::RecordNotFound
      redirect_to root_path
    end

  end
end
