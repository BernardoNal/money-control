class TransactionsController < ApplicationController
  before_action :set_transaction, only: %i[show edit update destroy]
  before_action :set_categories, only: %i[new create edit update]
  before_action :set_accounts, only: %i[new create edit update]

  def index
    @transactions = policy_scope(Transaction).order(date: :desc)
  end

  def show
  end

  def new
    @transaction = Transaction.new
    render :form
  end

  def create
    @transaction = Transaction.new(transaction_params)

    set_transaction_account
    return if performed?

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
      :category_id,
      :account_id
    )
  end

  def set_transaction
    @transaction = Transaction.find(params[:id])
    authorize @transaction
  end

  def set_categories
    @categories = Category.all
  end

  def set_accounts
    @accounts = Account.where(user: current_user)
  end

  def set_transaction_account
    @transaction.account = current_user.accounts.find(
      transaction_params[:account_id]
    )
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path
  end

  def current_user_transactions
    Transaction.joins(:account).where(accounts: { user_id: current_user.id })
  end
end
