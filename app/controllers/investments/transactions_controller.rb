module Investments
  class TransactionsController < ApplicationController
    before_action :set_transaction, only: %i[
      show
      edit
      update
      destroy
    ]

    def index
      @transactions = user_transactions
        .includes(:asset, :portfolio)
        .order(date: :desc)
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

      load_form_collections

      if @transaction.save
        redirect_to investments_transaction_path(@transaction),
                    notice: "Movimentação criada com sucesso."
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
                    notice: "Movimentação alterada com sucesso."
      else
        render :form, status: :unprocessable_entity
      end
    end

    def destroy
      @transaction.destroy

      redirect_to investments_transactions_path,
                  notice: "Movimentação removida com sucesso."
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
      @transaction = user_transactions.find(params[:id])
    end

    def user_transactions
      Investments::Transaction
        .joins(:portfolio)
        .where(
          investments_portfolios: {
            user_id: current_user.id
          }
        )
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
  end
end
