class TransactionsController < ApplicationController
  before_action :set_transaction, only: %i[show edit update destroy]
  before_action :set_categories, only: %i[new create edit update]

  def index
    @transactions = Transaction.order(date: :desc)
  end

  def show
  end

  def new
    @transaction = Transaction.new
    render :form
  end

  def create
    @transaction = Transaction.new(transaction_params)
    @transaction.account = Account.first

    if @transaction.save
      redirect_to transaction_path(@transaction), notice: "Transação criada com sucesso."
    else
      render :form, status: :unprocessable_entity
    end
  end

  def edit
    render :form
  end

  def update
    if @transaction.update(transaction_params)
      redirect_to transaction_path(@transaction), notice: "Transação atualizada com sucesso."
    else
      render :form, status: :unprocessable_entity
    end
  end

  def destroy
    @transaction.destroy

    redirect_to transactions_path,
                notice: "Transação excluída com sucesso."
  end

  private

  def transaction_params
    params.require(:transaction).permit(
      :amount,
      :description,
      :to_whom,
      :payment_method,
      :date,
      :category_id
    )
  end

  def set_transaction
    @transaction = Transaction.find(params[:id])
  end

  def set_categories
    @categories = Category.all
  end
end
