class TransactionsController < ApplicationController
  before_action :set_transaction, only: %i[show edit update destroy]
  def index
    @transactions = Transaction.all
  end

  def show
  end

  def new
    @transaction = Transaction.new
    @categories = Category.all
    render :form
  end

  def create
    @categories = Category.all
    @account = Account.first
    @transaction = Transaction.new(transaction_params)
    @transaction.account = @account

    if @transaction.save
      redirect_to transaction_path(@transaction)
      flash[:alert] = "Conta criada com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @categories = Category.all
     render :form
  end

  def update
    @categories = Category.all
    @account = Account.first
    @transaction = Transaction.find(params[:id])
    @transaction.account = @account

    if @transaction.update(transaction_params)
      flash[:alert] = "Transação atualizada com sucesso."
      redirect_to transaction_path(@transaction)
    else
      render :edit, status: :unprocessable_entity
    end
  end


  def destroy
    @transaction.destroy
    flash[:alert] = "Conta excluída com sucesso."

    redirect_to transactions_path()
  end

  private

  # Permits transaction parameters
  def transaction_params
    params.require(:transaction).permit( :amount, :description, :to_whom, :payment_method, :date, :category_id)
  end

  def set_transaction
    @transaction = Transaction.find(params[:id])
  end
end
